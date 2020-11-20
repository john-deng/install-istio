#!/bin/bash -e

#####################################
#
# Set up two kind clusters:
#   1. a management cluster
#   2. a target cluster
#
#
#####################################

if [ "$1" == "cleanup" ]; then
  kind get clusters | grep -E '(cluster)-*' | while read -r r; do kind delete cluster --name $r; done
  exit 0
fi

#!/bin/bash
WORKSPACE=${PWD}

export KUBECONFIG=~/.kube/config
export PATH=$PATH:${WORKSPACE}/bin
CLUSTER_NAME="mesher"

reg_port='5000'
endpoint=''

echo
echo
echo "http://solarmesh.cn"
echo
status=1
spin="/-\|"

user_memory=$(free | awk '{print $7}' | awk 'NR==2')
min_memory=4091456
if [[ ${user_memory} -lt ${min_memory} ]]; then
  echo 'Error: At least 6G of available memory is required'
  exit 1
fi

menu() {
    echo "Avaliable options:"
    for i in ${!options[@]}; do 
        printf "%3d%s) %s\n" $((i+1)) "${choices[i]:- }" "${options[i]}"
    done
    if [[ "$msg" ]]; then echo "$msg"; fi
}

ip_addr=$(ip a | grep -v kube | grep -v 127.0.0.1 | grep -v docker | grep -v 'br\-' | grep inet | grep -v inet6 | sed 's/\//\ /g' | awk '{print $2}')
options=(${ip_addr})

options_num="${#options[@]}"
#echo options_num: $options_num

if [ "${options_num}" == "0" ]; then
  read -p "Please enter your host IP address: " ip
elif [ "${options_num}" == "1" ]; then 
  ip=${options[0]}
else
  echo "ip: ${ip_addr}"

  prompt="Please Select your host IP adress: "
  while menu && read -rp "$prompt" num && [[ "$num" ]]; do
      [[ "$num" != *[![:digit:]]* ]] &&
      (( num > 0 && num <= ${#options[@]} )) ||
      { msg="Invalid option: $num"; continue; }
      ((num--)); msg="${options[num]} was ${choices[num]:+un}checked"
      [[ "${choices[num]}" ]] && choices[num]="" || choices[num]="+"

      if [[ "${choices[num]}" ]]; then
        break
      fi
  done

  result=""
  printf "You selected host IP address: "; msg=" nothing"
  for i in ${!options[@]}; do
      if [[ "${choices[i]}" ]]; then
          printf " %s" "${options[i]}"
          msg=""
          result="${result} ${options[i]}"
      fi
  done

ip=${result}

fi

ip="${ip#"${ip%%[![:space:]]*}"}"
echo ""
echo "${ip}"
echo ""

cluster_name=$1

reg_name='kind-registry'
reg_port='5000'

INET='eth0'

work_dir="$PWD"
#INGRESS_HOST=$(ifconfig ${INET} | grep -v inet6 | grep inet | awk '{print $2}')
#echo ${INGRESS_HOST}

# The default version of k8s under Linux is 1.18
# https://github.com/solo-io/service-mesh-hub/issues/700
kindImage=kindest/node:v1.17.5

# set up each cluster
# Create NodePort for remote cluster so it can be reachable from the management plane.
# This config is roughly based on: https://kind.sigs.k8s.io/docs/user/ingress/


# Create NodePort for remote cluster so it can be reachable from the management plane.
# This config is roughly based on: https://kind.sigs.k8s.io/docs/user/ingress/
function install_cluster() (

  kubeport=$2

  cat <<EOF | kind create cluster --name $1 --image $kindImage --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
#containerdConfigPatches:
#- |-
#  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${reg_port}"]
#    endpoint = ["http://${reg_name}:${reg_port}"]
networking:
  apiServerAddress: "${ip}"
  apiServerPort: $kubeport
nodes:
- role: control-plane   
- role: worker      

EOF

  wait

  for node in $(kind get nodes); do
    kubectl annotate node "${node}" "kind.x-k8s.io/registry=localhost:${reg_port}";
  done
  printf "\n\n---\n"
  echo "Finished setting up cluster $1"

)

if [[ $(kind get clusters | grep master | wc -l) < 1 ]]; then

install_cluster $@

fi

cd "${work_dir}"

# Post installations

cluster=kind-$1

kubectl --context $cluster apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/namespace.yaml
kubectl --context $cluster -n metallb-system apply -f https://raw.githubusercontent.com/metallb/metallb/v0.9.4/manifests/metallb.yaml
kubectl --context $cluster create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
kubectl --context $cluster -n metallb-system apply -f metallb-$1.yaml

echo '✔ Clusters have been created'
