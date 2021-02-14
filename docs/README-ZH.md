[英文文档](../README.md)

# 一步安装istio多集群

当每次 Istio 有新版本发布，如果你跃跃欲试，那你找对地方了，本工具将安装步骤简化成只需要一步即可安装Istio多集群。

## 安装前的准备工作

首先你要准备好两个安装好的K8s集群，如果你觉得安装K8s集群太麻烦，建议你使用KinD工具来快速安装K8s，别担心，我已经准备好了另外一个意见安装K8s的工具[mercury](https://github.com/solarmesh-io/mercury), 去[这里](https://github.com/solarmesh-io/mercury)看详细信息。


## 安装Istio多集群

当你准备好了两个K8s集群之后，在 terminal 克隆这个项目

```bash
git clone https://github.com/john-deng/install-istio.git
cd install-istio
./install 1.9.0 # 参数 1.9.0 表示你要安装 Istio 1.9.0
```

## 验证跨集群流量

要验证跨集群负载均衡是否按预期工作，请使用 Sleep pod 多次调用 HelloWorld 服务。为确保负载均衡工作正常，请从部署中的所有集群调用HelloWorld服务。

从集群1上的Sleep pod向HelloWorld服务发送一个请求：

```bash
while true; do
kubectl exec --context=kind-cluster1 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster1 -n sample -l \
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
kubectl exec --context=kind-cluster2 -n sample -c sleep \
    "$(kubectl get pod --context=kind-cluster2 -n sample -l \
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