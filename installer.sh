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

export KRD_ADDONS=virtlet
export KRD_ENABLE_MULTUS=false
KRD_ACTIONS=("install_k8s" "install_k8s_addons")
curl -fsSL http://bit.ly/KRDaio | KRD_ACTIONS_DECLARE=$(declare -p KRD_ACTIONS) bash

printf "Waiting for Virtlet services..."
until kubectl get pods -n kube-system | grep "virtlet-.*Running"; do
    printf "."
    sleep 2
done
./test.sh | tee ~/test.log
