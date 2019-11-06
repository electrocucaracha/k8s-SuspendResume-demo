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

echo "127.0.0.1       localhost      $(hostname)" | sudo tee /etc/hosts

export KRD_ADDONS=virtlet
export KRD_ENABLE_MULTUS=false
KRD_ACTIONS=("install_k8s" "install_k8s_addons")
curl -fsSL http://bit.ly/KRDaio | KRD_ACTIONS_DECLARE=$(declare -p KRD_ACTIONS) bash

pushd /opt/krd/tests
./virtlet.sh
popd