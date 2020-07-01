#!/bin/bash - 

set -o nounset                              # Treat unset variables as an error

# install prereqs

apt-get update && apt-get install rsync -y

K8S_REPO=http://github.com/kubernetes/kubernetes
K8S_SRC_PATH=${K8S_SRC_PATH:-/go/src/k8s.io/kubernetes}

trap "rm -f ${K8S_SRC_PATH}" ERR 

rm -rf ${K8S_SRC_PATH}
git clone ${K8S_REPO} ${K8S_SRC_PATH}

pushd ${K8S_SRC_PATH}

# building e2e bins
make WHAT="test/e2e/e2e.test"
make WHAT="vendor/github.com/onsi/ginkgo/ginkgo"

popd


