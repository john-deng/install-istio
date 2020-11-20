# Istio 1.8 Multiple Cluster Installation with one step

Istio 1.8.0 just released, the greatest new feature is that the mulitcluster installation is simplified and I simplified the installation even futher, only one step is needed.

## Clone this project

Clone the this project in the terminal, 

```bash
git clone https://github.com/john-deng/istio-1.8.git
cd istio-1.8
```

## Prerequisition

First of all, you need to install docker and prepare two Kubernetes clusters, in my case, I chose [Kind](https://kind.sigs.k8s.io/) for the sake of simplicity.

```bash
cd kind
./setup.sh cluster01 6443
./setup.sh cluster02 6444
cd ..
```

## Install Istio with one step

```bash

cd istio && ./install.sh

```

## Verifying Cross-Cluster Traffic

To verify that cross-cluster load balancing works as expected, call the HelloWorld service several times using the Sleep pod. To ensure load balancing is working properly, call the HelloWorld service from all clusters in your deployment.

Send one request from the Sleep pod on cluster1 to the HelloWorld service:

```bash
while true; do
kubectl exec --context=kind-cluster01 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster01 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -s helloworld.sample:5000/hello
done
```

Repeat this request several times and verify that the HelloWorld version should toggle between v1 and v2:

```bash
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v1, instance: helloworld-v1-578dd69f69-sbvc9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v1, instance: helloworld-v1-578dd69f69-sbvc9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
```

Now repeat this process from the Sleep pod on cluster2:

```bash
while true; do
kubectl exec --context=kind-cluster02 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster02 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -s helloworld.sample:5000/hello
done

```

Repeat this request several times and verify that the HelloWorld version should toggle between v1 and v2:

```bash
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v1, instance: helloworld-v1-578dd69f69-sbvc9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v1, instance: helloworld-v1-578dd69f69-sbvc9
```

Congratulations! You successfully installed and verified Istio on multiple clusters!

if you are interested in Service Mesh, find us [here](http://solarmesh.cn).