### This repo contains a set of "tools" used to ease the pain of running K8S e2e tests

Using these tools assumes that you are running this from the master node of a k8s cluster.

#### Deploying a K8s Cluster with Windows Nodes via aks-engine

In order to deploy K8s Clusters in Azure, the recommended approach is to use [aks-engine](http://github.com/Azure/aks-engine)

Prereqs:
- Azure subscription
- azcli

##### Download aks-engine release

Scenarios:
- Using Dockershimsa

In order to deploy using Dockershim, you can get the version of aks-engine used in upstream e2e tests for Windows from the following URL:

```
curl https://aka.ms/aks-engine/aks-engine-k8s-e2e.tar.gz -o aks-engine.tar.gz
tar -xvf aks-engine.tar.gz

``` 

- Using ContainerD

ContainerD with Hyper-V isolation  support is not officially added in aks-engine at the moment, as such, we will use a custom aks-engine with support for this. 
NOTE: This is the version used for upstream tests.
```
curl https://k8swin.blob.core.windows.net/k8s-windows/aks-engine-ce5c82940-marosset-hyperv.tar.gz -o aks-engine.tar.gz
tar -xvf aks-engine.tar.gz
```

#### Get aks-engine api-model for deployment

In order to deploy a cluster using aks-engine, you will need a aks-engine api model. The recommended route for deploying clusters for e2e testing is to use one of the
api-model templates that is used in upstream e2e-testing. You can find those templates here: https://github.com/kubernetes-sigs/windows-testing/tree/master/job-templates

For example, if we want to deploy a cluster with containerd with Hyper-V isolation, we would use the following template:
```
curl https://github.com/kubernetes-sigs/windows-testing/blob/master/job-templates/kubernetes_containerd_hyperv.json -o kubernetes_container_hyperv.json
```

#### Customize the template for your needs

The downloaded template needs to have some fields filled before we can attempt deployment:

- masterProfile.dnsPrefix: custom dns prefix for the master node of the cluster
- windowsProfile.adminPassword: password for the Windows Nodes of the cluster.
- linuxProfile.ssh.publicKeys.keyData: ssh public key to be set for ssh access to the master node of the newly deployd cluster.
- servicePrincipalProfile.clientID and servicePrincipalProfile.secret: clientId + Secret for a service principal that has access to modify resources in chosen Azure Subscription. More details [here](https://github.com/Azure/aks-engine/blob/077f396b69fd5674fc05e130fe8780045f136d9d/docs/topics/service-principals.md)

#### Generate ARM templates with aks-engine

```
./aks-engine generate kubernetes_containerd_hyperv.json
```
 The output of the generate command will be in `./_output/ClusterDnsPrefix/`

#### Deploy cluster from ARM templates

Be sure to be logged in to azcli

```
# create resource group for cluster
az group create --name rg_name -l westus2

# deploy cluster
cd ./_output/ClusterDnsPrefix/

az group deployment create -g rg_name --template-file ./azuredeploy.json --parameters azuredeploy.parameters.json --name deployment_name --verbose
```

After deployment is finished, you can access your cluster via ssh to the master node or you can find the kubeconfig file for the cluster in the _output folder.

#### Building k8s e2e test binaries

In order to build the binaries without the need to setup a go environment, this repo provides a pod spec & a builder script so that all k8s cloning & building operations could happen in isolation. Artifacts are placed in a hostPath volume containing the cloned k8s repo.

Prereqs:
- envsubst


Create build pod:

``` 
   export K8S_PATH=path_to_host_volume
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

