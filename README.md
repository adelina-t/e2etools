### This repo contains a set of "tools" used to ease the pain of running K8S e2e tests

Using these tools assumes that you are running this from the master node of a k8s cluster.

#### Building k8s e2e test binaries

In order to build the binaries without the need to setup a go environment, this repo provides a pod spec & a builder script so that all k8s cloning & building operations could happen in isolation. Artifacts are placed in a hostPath volume containing the cloned k8s repo.

Prereqs:
- envsubst


Create build pod:

``` export K8S_PATH=path_to_host_volume
    cat e2e-builder.template.yaml | envsubst | kubectl create -f -
```

Wait for build pod to complete:
` kubectl logs -f e2e-builder `

#### Download kubetest
 
You can use a built, stable version of kubetest from the following link:

``` 
    curl kubetest-link=https://k8swin.blob.core.windows.net/k8s-windows/kubetest -o $K8S_PATH/kubetest
    chmod +x $K8S_PATH/kubetest
```

#### Download test repo_list

For the moment images used for windows e2e tests are not located alongside the default linux ones. As such you need to indicate the repo list for the windows images via a env var:

```
export KUBE_TEST_REPO_LIST=/tmp/repo_list
curl https://raw.githubusercontent.com/kubernetes-sigs/windows-testing/master/images/image-repo-list -o $KUBE_TEST_REPO_LIST
```

#### Setup environment for e2e testing

In order to connect to the cluster to be tested, some env variables need to be set

```
export KUBE_MASTER=local
export KUBE_MASTER_IP=ip_of_api_server
export KUBE_MASTER_URL=https://$KUBE_MASTER_IP
exprot KUBECTL_PATH=`which kubectl`
```

#### Run e2e tests

NOTE: you must be in the k8s folder for this

```
./kubetest --ginkgo-parallel=2 --provider=skeleton --test --test_args=--ginkgo.flakeAttempts=1 --num-nodes=2 --ginkgo.noColor --ginkgo.dryRun=${DRY_RUN} --ginkgo.focus=${GINKGO_FOCUS} --ginkgo.skip=${GINKGO_SKIP} --node-os-distro=windows
```

```
```

