#!/bin/bash - 

set -o nounset                              # Treat unset variables as an error

# install prereqs

apt-get update && apt-get install rsync -y

K8S_REPO=http://github.com/kubernetes/kubernetes
K8S_SRC_PATH=${K8S_SRC_PATH:-/go/src/k8s.io/kubernetes}

if git clone ${K8S_REPO} ${K8S_SRC_PATH}; then
       echo "Error cloning k8s repo."

pushd ${K8S_SRC_PATH}

# building e2e bins
make WHAT="test/e2e/e2e.test"
make WHAT="vendor/github.com/onsi/ginkgo/ginkgo"

popd


