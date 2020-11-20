#!/bin/bash

echo
echo
echo "http://solarmesh.cn"
echo

# Install Multi-Primary on different networks

export CTX_CLUSTER1_NAME=cluster01
export CTX_CLUSTER2_NAME=cluster02

export CTX_CLUSTER1=kind-${CTX_CLUSTER1_NAME}
export CTX_CLUSTER2=kind-${CTX_CLUSTER2_NAME}

export CTX_CLUSTER1_MESH_NAME=mesh1
export CTX_CLUSTER2_MESH_NAME=mesh2

export CTX_CLUSTER1_NETWORK=network1
export CTX_CLUSTER2_NETWORK=network2

ISTIO_MAJOR_VER=1.8
ISTIO_MINOR_VER=0

work_dir="$PWD"
istio_dir="$work_dir/istio-${ISTIO_MAJOR_VER}.${ISTIO_MINOR_VER}"

wget https://storage.googleapis.com/istio-release/releases/${ISTIO_MAJOR_VER}.${ISTIO_MINOR_VER}/istio-${ISTIO_MAJOR_VER}.${ISTIO_MINOR_VER}-linux-amd64.tar.gz

tar xvf istio-${ISTIO_MAJOR_VER}.${ISTIO_MINOR_VER}-linux-amd64.tar.gz

export PATH=$istio_dir/bin:$PATH

function shutdown() {
  tput cnorm # reset cursor
}
trap shutdown EXIT

function cursorBack() {
  echo -en "\033[$1D"
}

function wait_with_spinner() {
  # make sure we use non-unicode character type locale 
  # (that way it works for any locale as long as the font supports the characters)
  local LC_CTYPE=C

  local cmd="$1"
  local interval=$2
  local wait_with_spinner_type=$3

  if [[ "${wait_with_spinner_type}" == "" ]]; then
    wait_with_spinner_type=$(($RANDOM % 12))
  fi

  case ${wait_with_spinner_type} in
  0)
    local spin='⠁⠂⠄⡀⢀⠠⠐⠈'
    local charwidth=3
    ;;
  1)
    local spin='-\|/'
    local charwidth=1
    ;;
  2)
    local spin="▁▂▃▄▅▆▇█▇▆▅▄▃▂▁"
    local charwidth=3
    ;;
  3)
    local spin="▉▊▋▌▍▎▏▎▍▌▋▊▉"
    local charwidth=3
    ;;
  4)
    local spin='←↖↑↗→↘↓↙'
    local charwidth=3
    ;;
  5)
    local spin='▖▘▝▗'
    local charwidth=3
    ;;
  6)
    local spin='┤┘┴└├┌┬┐'
    local charwidth=3
    ;;
  7)
    local spin='◢◣◤◥'
    local charwidth=3
    ;;
  8)
    local spin='◰◳◲◱'
    local charwidth=3
    ;;
  9)
    local spin='◴◷◶◵'
    local charwidth=3
    ;;
  10)
    local spin='◐◓◑◒'
    local charwidth=3
    ;;
  11)
    local spin='⣾⣽⣻⢿⡿⣟⣯⣷'
    local charwidth=3
    ;;
  esac

  charwidth=1

  local i=0
  tput civis # cursor invisible
  
  while [[ ${interval} -gt 0 ]]; do
    "${cmd}" >/dev/null 2>&1
    if [[ $? == 0 ]]; then
      break
    fi

    local i=$(((i + $charwidth) % ${#spin}))
    printf "%s" "${spin:$i:$charwidth}"

    cursorBack 1
    sleep .1

    ((interval--))
  done
  tput cnorm
  
  return $?
}

#wait_with_spinner "ping google.com -c 3" 20
#exit

pushd $istio_dir

function create_certs() {
  ctx=$1

  if [[ $(kubectl get secret cacerts -n istio-system --context=${ctx} | grep -v NAME | wc -l ) < 1 ]]; then

  kubectl create namespace istio-system --context=${ctx}
  kubectl create secret generic cacerts -n istio-system --context=${ctx} \
      --from-file=samples/certs/ca-cert.pem \
      --from-file=samples/certs/ca-key.pem \
      --from-file=samples/certs/root-cert.pem \
      --from-file=samples/certs/cert-chain.pem

  fi
}

# Configure Trust

create_certs ${CTX_CLUSTER1}
create_certs ${CTX_CLUSTER2}

# Set the default network for cluster1

kubectl --context="${CTX_CLUSTER1}" get namespace istio-system && \
kubectl --context="${CTX_CLUSTER1}" label namespace istio-system topology.istio.io/network=${CTX_CLUSTER1_NETWORK}

# Configure cluster1 as a primary

cat <<EOF > ${CTX_CLUSTER1}.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: ${CTX_CLUSTER1_MESH_NAME}
      multiCluster:
        clusterName: ${CTX_CLUSTER1}
      network: ${CTX_CLUSTER1_NETWORK}
EOF

# Apply the configuration to cluster1:
istioctl install --context="${CTX_CLUSTER1}" -f ${CTX_CLUSTER1}.yaml
if [[ $? == 0 ]]; then 
  wait_with_spinner "kubectl --context="${CTX_CLUSTER1}"  -n istio-system get pod -l app=istiod | grep Running | grep 1/1" 100
fi

# Install the east-west gateway in cluster1
kubectl --context="${CTX_CLUSTER1}" -n istio-system get pod -l app=istio-eastwestgateway | grep Running | grep 1/1
if [[ $? != 0 ]]; then
  samples/multicluster/gen-eastwest-gateway.sh \
      --mesh ${CTX_CLUSTER1_MESH_NAME} --cluster ${CTX_CLUSTER1} --network ${CTX_CLUSTER1_NETWORK} | \
      istioctl --context="${CTX_CLUSTER1}" install -y -f -

  if [[ $? == 0 ]]; then 
    wait_with_spinner "kubectl --context="${CTX_CLUSTER1}" -n istio-system get pod -l app=istio-eastwestgateway | grep Running | grep 1/1" 100
  fi
fi
# Wait for the east-west gateway to be assigned an external IP address:
kubectl --context="${CTX_CLUSTER1}" get svc istio-eastwestgateway -n istio-system

# Expose services in cluster1
kubectl --context="${CTX_CLUSTER1}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml

# Set the default network for cluster2
kubectl --context="${CTX_CLUSTER2}" get namespace istio-system && \
  kubectl --context="${CTX_CLUSTER2}" label namespace istio-system topology.istio.io/network=${CTX_CLUSTER2_NETWORK}

# Configure cluster2 as a primary
cat <<EOF > ${CTX_CLUSTER2}.yaml
apiVersion: install.istio.io/v1alpha1
kind: IstioOperator
spec:
  values:
    global:
      meshID: ${CTX_CLUSTER2_MESH_NAME}
      multiCluster:
        clusterName: ${CTX_CLUSTER2}
      network: ${CTX_CLUSTER2_NETWORK}
EOF

istioctl install --context="${CTX_CLUSTER2}" -f ${CTX_CLUSTER2}.yaml

if [[ $? == 0 ]]; then 
  wait_with_spinner "kubectl --context="${CTX_CLUSTER2}"  -n istio-system get pod -l app=istiod | grep Running | grep 1/1" 100
fi

# Install the east-west gateway in cluster2
kubectl --context="${CTX_CLUSTER2}" -n istio-system get pod -l app=istio-eastwestgateway | grep Running | grep 1/1
if [[ $? != 0 ]]; then
  samples/multicluster/gen-eastwest-gateway.sh \
      --mesh ${CTX_CLUSTER2_MESH_NAME} --cluster ${CTX_CLUSTER2} --network ${CTX_CLUSTER2_NETWORK} | \
      istioctl --context="${CTX_CLUSTER2}" install -y -f -
  if [[ $? == 0 ]]; then 
    wait_with_spinner "kubectl --context="${CTX_CLUSTER2}" -n istio-system get pod -l app=istio-eastwestgateway | grep Running | grep 1/1" 100
  fi
fi
# Wait for the east-west gateway to be assigned an external IP address:
kubectl --context="${CTX_CLUSTER2}" get svc istio-eastwestgateway -n istio-system

# Expose services in cluster2
kubectl --context="${CTX_CLUSTER2}" apply -n istio-system -f \
    samples/multicluster/expose-services.yaml

# Enable Endpoint Discovery
# nstall a remote secret in cluster2 that provides access to cluster1’s API server.
istioctl x create-remote-secret \
  --context="${CTX_CLUSTER1}" \
  --name=${CTX_CLUSTER1} | \
  kubectl apply -f - --context="${CTX_CLUSTER2}"

# Install a remote secret in cluster1 that provides access to cluster2’s API server.
istioctl x create-remote-secret \
  --context="${CTX_CLUSTER2}" \
  --name=${CTX_CLUSTER2} | \
  kubectl apply -f - --context="${CTX_CLUSTER1}"

# Verify the installation

## Deploy the HelloWorld Service
kubectl create --context="${CTX_CLUSTER1}" namespace sample
kubectl create --context="${CTX_CLUSTER2}" namespace sample

kubectl label --context="${CTX_CLUSTER1}" namespace sample \
    istio-injection=enabled
kubectl label --context="${CTX_CLUSTER2}" namespace sample \
    istio-injection=enabled

kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l service=helloworld -n sample

## Deploy HelloWorld V1

kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v1 -n sample

kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=helloworld

## Deploy HelloWorld V2
kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/helloworld/helloworld.yaml \
    -l version=v2 -n sample

kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=helloworld

# Deploy Sleep
kubectl apply --context="${CTX_CLUSTER1}" \
    -f samples/sleep/sleep.yaml -n sample
kubectl apply --context="${CTX_CLUSTER2}" \
    -f samples/sleep/sleep.yaml -n sample

kubectl get pod --context="${CTX_CLUSTER1}" -n sample -l app=sleep
kubectl get pod --context="${CTX_CLUSTER2}" -n sample -l app=sleep

popd