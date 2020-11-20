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
