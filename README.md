# Istio 1.8 Multiple Cluster Installation with 2 Kind Clusters

## 1. Clone this project

```bash
git clone git@github.com:john-deng/istio-1.8.git
cd istio-1.8
```

## 2. Install Kind Clusters

```bash
kind/setup.sh cluster01 6443
kind/setup.sh cluster02 6444
```


## 3. Install Istio

```bash

istio/install.sh

```

## 4. Verifying Cross-Cluster Traffic

To verify that cross-cluster load balancing works as expected, call the HelloWorld service several times using the Sleep pod. To ensure load balancing is working properly, call the HelloWorld service from all clusters in your deployment.

Send one request from the Sleep pod on cluster1 to the HelloWorld service:

```bash
kubectl exec --context=kind-cluster01 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster01 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello
```

Repeat this request several times and verify that the HelloWorld version should toggle between v1 and v2:

```bash
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
```

Now repeat this process from the Sleep pod on cluster2:

```bash
kubectl exec --context=kind-cluster02 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster02 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl helloworld.sample:5000/hello

```

Repeat this request several times and verify that the HelloWorld version should toggle between v1 and v2:

```bash
Hello version: v2, instance: helloworld-v2-758dd55874-6x4t8
Hello version: v1, instance: helloworld-v1-86f77cd7bd-cpxhv
```

Congratulations! You successfully installed and verified Istio on multiple clusters!