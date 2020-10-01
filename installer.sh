#!/bin/bash
# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c)
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -o pipefail
set -o errexit
set -o nounset

export KRD_CERT_MANAGER_ENABLED=false
export KRD_INGRESS_NGINX_ENABLED=false
export KRD_ADDONS=virtlet

curl -fsSL http://bit.ly/KRDaio | bash
pushd /opt/krd
./krd_command.sh -a install_k8s_addons
popd
kubectl rollout status daemonset.apps/virtlet -n kube-system --timeout=5m
if ! command -v mkpasswd; then
    curl -fsSL http://bit.ly/install_pkg | PKG=whois bash
fi
