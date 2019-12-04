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

source common.sh

function _test_burstable {
    msg "=== Test Virtlet VM with Burstable QoS class ==="
    _setup ""

    _trigger_cpu_stress_pod
    # NOTE: VM running + Pod running

    vm_name="$(_get_vm_name)"
    msg "Suspending $vm_name"
    kubectl virt virsh suspend "$vm_name" > /dev/null
    _print_cpu_usage 3

    _trigger_cpu_stress_pod
    # NOTE: VM suspended + Pod running

    msg "Resuming $vm_name"
    kubectl virt virsh resume "$vm_name" > /dev/null
    _print_cpu_usage 3

    _teardown
}

function _test_guaranteed {
    msg "=== Test Virtlet VM with Guaranteed QoS class ==="
    _setup 2

    msg "Creating cpu stress pod"
    kubectl apply -f linux_pod.yaml --force > /dev/null
    # NOTE: VM running + Pod pending
    sleep 5
    printf "\nLinux job events:\n"
    kubectl get event --field-selector involvedObject.name=linux-job --sort-by='.lastTimestamp'

    kubectl delete pod "$virtlet_pod_name" > /dev/null
    msg "Destroying VM..."
    until kubectl get pods "$virtlet_pod_name" --ignore-not-found --no-headers > /dev/null ; do
        printf "."
        sleep 2
    done
    _print_node__resources
    msg "Waiting for linux-job to start..."
    until kubectl get pod linux-job -o 'jsonpath={.status.phase}'  | grep "Running"; do
        printf "."
        sleep 2
    done
    # NOTE: VM destroyed + Pod running
    _print_node__resources
    _print_cpu_usage 3

    _teardown
}

# main() - Base testing setup shared among functional tests
function main {
    _teardown

    _test_burstable
    _test_guaranteed

    printf "\nTests completed!!!\n"
}

main
