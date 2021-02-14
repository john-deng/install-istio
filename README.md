[中文文档](./docs/README-ZH.md)

# Istio Multiple Cluster Installation with one step

Once an Istio new version is released, you may want to try and evaluate what is new in this version, here is the simplest way to do it, just one step is needed.

## Prerequisites

Prepare two kubernetes clusters, I recommend to use KinD for the sake of testing and I've already made a tool called [mercury](https://github.com/solarmesh-io/mercury) for you.


## Getting started

Clone the this project in the terminal

```bash
git clone https://github.com/john-deng/install-istio.git
cd install-istio
./install 1.9.0
```

## Verifying Cross-Cluster Traffic

To verify that cross-cluster load balancing works as expected, call the HelloWorld service several times using the Sleep pod. To ensure load balancing is working properly, call the HelloWorld service from all clusters in your deployment.

Send one request from the Sleep pod on cluster1 to the HelloWorld service:

```bash
while true; do
kubectl exec --context=kind-cluster1 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster1 -n sample -l \
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
kubectl exec --context=kind-cluster2 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster2 -n sample -l \
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