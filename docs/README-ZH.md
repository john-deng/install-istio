[英文文档](../README.md)

# 一步安装istio 1.8多集群

Istio 1.8.0刚刚发布，最大的新特性就是简化了mulitcluster的安装，我把安装更加的简化，只需要一步。

## Clone this project

在 terminal 克隆这个项目

```bash
git clone https://github.com/john-deng/istio-1.8.git
cd istio-1.8
```

## 安装前的准备

首先，你需要安装docker，并准备两个Kubernetes集群，在我的例子中，为了简单起见，我选择了[Kind](https://kind.sigs.k8s.io/)。

```bash

./setup.sh cluster01 6443
./setup.sh cluster02 6444

```

## 一步安装istio

```bash

./install.sh

```

## 验证跨集群流量

要验证跨集群负载均衡是否按预期工作，请使用 Sleep pod 多次调用 HelloWorld 服务。为确保负载均衡工作正常，请从部署中的所有集群调用HelloWorld服务。

从集群1上的Sleep pod向HelloWorld服务发送一个请求：

```bash
while true; do
kubectl exec --context=kind-cluster01 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster01 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -s helloworld.sample:5000/hello
done
```

重复这个请求几次，并验证HelloWorld的版本应该在v1和v2之间切换：

```bash
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v1, instance: helloworld-v1-578dd69f69-sbvc9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v1, instance: helloworld-v1-578dd69f69-sbvc9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
```

现在从集群2上重复这个过程

```bash
while true; do
kubectl exec --context=kind-cluster02 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster02 -n sample -l \
    app=sleep -o jsonpath='{.items[0].metadata.name}')" \
    -- curl -s helloworld.sample:5000/hello
done

```

重复这个请求几次，并验证HelloWorld的版本应该在v1和v2之间切换。

```bash
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v1, instance: helloworld-v1-578dd69f69-sbvc9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v2, instance: helloworld-v2-776f74c475-h7rd9
Hello version: v1, instance: helloworld-v1-578dd69f69-sbvc9
```

可以看到，我们成功地在多个集群上安装并验证了istio!

如果您对Service Mesh感兴趣，请关注我们的项目[SolarMesh](http://solarmesh.cn)。