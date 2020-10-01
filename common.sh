#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2019
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o errexit
set -o nounset
set -o pipefail

virtlet_pod_name=virtlet-job

# _create_yaml_files() - This function creates the content of yaml file
# required for testing Virtlet
function _create_yaml_files {
    proxy="apt:"
    cloud_init_proxy=""
    if [[ -n "${HTTP_PROXY+x}" ]]; then
        proxy+="
        http_proxy: $HTTP_PROXY"
        cloud_init_proxy+="
        - export http_proxy=$HTTP_PROXY
        - export HTTP_PROXY=$HTTP_PROXY"
    fi
    if [[ -n "${HTTPS_PROXY+x}" ]]; then
        proxy+="
        https_proxy: $HTTPS_PROXY"
        cloud_init_proxy+="
        - export https_proxy=$HTTPS_PROXY
        - export HTTPS_PROXY=$HTTPS_PROXY"
    fi
    if [[ -n "${NO_PROXY+x}" ]]; then
        cloud_init_proxy+="
        - export no_proxy=$NO_PROXY
        - export NO_PROXY=$NO_PROXY"
    fi
    cat << EOF > "$virtlet_pod_name.yaml"
apiVersion: v1
kind: Pod
metadata:
  name: $virtlet_pod_name
  annotations:
    kubernetes.io/target-runtime: virtlet.cloud
    VirtletVCPUCount: "${1:-1}"
    VirtletLibvirtCPUSetting: |
      mode: host-passthrough
    VirtletCloudInitUserData: |
      ssh_pwauth: True
      users:
      - name: demo
        gecos: User
        primary-group: testuser
        groups: users
        lock_passwd: false
        shell: /bin/bash
        # the password is "demo"
        passwd: $(mkpasswd --method=SHA-512 --rounds=4096 demo)
        sudo: ALL=(ALL) NOPASSWD:ALL
      $proxy
      runcmd:
      $cloud_init_proxy
        - curl -fsSL http://bit.ly/install_pkg | PKG=stress PKG_UPDATE=true bash
        - echo "Starting stress jobs"
        - until false; do echo "\$(date +%H:%M:%S) - Starting stress job..."; sudo stress --cpu 10 --timeout 590; echo "\$(date +%H:%M:%S) - Completed stress job"; sleep 10; done
spec:
  nodeSelector:
    extraRuntime: virtlet
  containers:
  - name: vm-worker
    image: virtlet.cloud/ubuntu/18.04
    imagePullPolicy: IfNotPresent
    # tty and stdin required for "kubectl attach -t" to work
    tty: true
    stdin: true
    resources:
      requests:
        memory: 2Gi
EOF
    if [ "${1:-}" ]; then
        cat << EOF >> "$virtlet_pod_name.yaml"
      limits:
        cpu: ${1:-1}
        memory: 2Gi
EOF
    fi
}

# msg() - Prints out specific message
function msg {
    printf "\n%s : %s" "$(date +%H:%M:%S)" "$1"
}

# _create_vm() - Create Virtlet VM
function _create_vm {
    kubectl create -f "$virtlet_pod_name.yaml" > /dev/null
    msg "Waiting for Virtlet VM to start..."
    kubectl wait --for=condition=ready pods "$virtlet_pod_name" --timeout=5m
    msg "$virtlet_pod_name $(kubectl describe pod virtlet-job | grep "QoS Class:")"

    vm_status=$(kubectl virt virsh list | grep "virtlet-.*-vm-worker" | awk '{print $3}')
    if [[ "$vm_status" != "running" ]]; then
        msg "There is no Virtual Machine running by $virtlet_pod_name pod"
        exit 1
    fi
    msg "Virsh domain: $(_get_vm_name)"
    msg "Waiting for Cloud Init service to install stress tools..."
    until kubectl logs "$virtlet_pod_name" | grep -q "Starting stress jobs"; do
        printf "."
        sleep 2
    done
}

# _get_vm_name() - Returns the VM name created by Virtlet
function _get_vm_name {
    kubectl virt virsh list | grep "virtlet-.*-vm-worker" | awk '{print $2}'
}

# _print_cpu_usage() - Prints the current CPU stas during one minute
function _print_cpu_usage {
    # shellcheck disable=SC2034
    for ((i=0; i<${1}; i++)); do
        if pgrep qemu > /dev/null ; then
            for child in $(pgrep qemu); do
                msg "qemu child process $child is using $(top -b -n 2 -d 0.2 -p "$child" | tail -1 | awk '{print $9}') % of CPU"
            done
        fi
        if pgrep stress > /dev/null ; then
            for child in $(pgrep stress); do
                msg "stress child process $child is using $(top -b -n 2 -d 0.2 -p "$child" | tail -1 | awk '{print $9}') % of CPU"
            done
        fi
        sleep 10
    done
}

# _print_node__resources() - Print Worker Node HW resources
function _print_node__resources {
    msg "Kubernetes Node Information - "
    kubectl describe nodes | grep "Capacity:" -A 1
    kubectl describe nodes | grep "Allocatable:" -A 1
    kubectl describe nodes | grep "Allocated resources:" -A 4
    total_pods=$(kubectl describe nodes | grep "Non-terminated Pods" | awk '{ print $3 }')
    table_rows=${total_pods#(}
    kubectl describe nodes | grep "Non-terminated Pods" -A $((table_rows+2))
}

# _trigger_cpu_stress_pod() - Creates a Pod with high priority class to stress CPU
function _trigger_cpu_stress_pod {
    msg "Creating cpu stress pod"
    kubectl apply -f linux_pod.yaml --force > /dev/null
    msg "Waiting for linux-job to start..."
    kubectl wait --for=condition=ready pods linux-job --timeout=5m
    _print_node__resources
    _print_cpu_usage 6
    msg "Destroying cpu stress pod"
    kubectl delete -f linux_pod.yaml --ignore-not-found=true --now > /dev/null
}

# _setup() - Creates testing resources
function _setup {
    pushd "$(mktemp -d)" > /dev/null
    eval "_create_yaml_files ${1:-}"
    _create_vm
    popd > /dev/null

    _print_cpu_usage 3
    _print_node__resources
}

# _teardown() - Destroys testing resources
function _teardown {
    kubectl delete events --field-selector involvedObject.name=linux-job > /dev/null
    kubectl delete pods --all --timeout=5m > /dev/null
}
