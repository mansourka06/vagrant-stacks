#!/bin/bash

set -e 

IP=$(hostname -I | awk '{print $2}')
hostname_ip=$IP

####################################################################################################
# Check the system based Distribution
if [ -f /etc/debian_version ]; then
    echo "Detected a Debian-based distribution."
    # Update package list
    sudo apt update
    # some settings for common server
    sudo apt install -y -qq curl git net-tools software-properties-common tree vim 2>&1 >/dev/null

## If the distribution is neither Red Hat-based nor Debian-based
else
    echo "Unsupported distribution. Only Ubuntu OS is supported !"
    exit 1
fi

#######################################
# Installing Kubernetes on Ubuntu VMs
#######################################

############ configure kubernetes cluster ############
## Disable Swap
sudo swapoff -a

## Create /etc/apt/keyrings if it does not exist by default
sudo mkdir -m 755 /etc/apt/keyrings

## Disable Swap
sudo swapoff -a

## Forwarding IPv4 and letting iptables see bridged traffic
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

sysctl net.bridge.bridge-nf-call-iptables net.bridge.bridge-nf-call-ip6tables net.ipv4.ip_forward

############ Install Kubernetes packages ############

#Update the apt package and install packages needed
sudo apt-get update && sudo apt-get upgrade
sudo apt-get install -y apt-transport-https ca-certificates curl

### Install containerd
sudo apt-get install -y containerd

#Create a containerd configuration file
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

#Restart containerd with the new configuration
sudo systemctl restart containerd

#### Install Kubernetes Components: kubelet kubeadm kubectl

#Download the public signing key for the Kubernetes package
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

#Add the appropriate Kubernetes apt repository
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

#Update and install the packages 
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl containerd

#check components status
sudo systemctl status kubelet.service
sudo systemctl status containerd.service

#Ensure both are set to start when the system start up
sudo systemctl enable containerd.service
sudo systemctl enable containerd.service

#Edit the kubelet systemd unit file:
# sudo systemctl edit kubelet

# [Service]
# ExecStart=
# ExecStart=/usr/bin/kubelet --container-runtime=remote --container-runtime-endpoint=unix:///var/run/containerd/containerd.sock

sudo systemctl daemon-reload
sudo systemctl restart kubelet 

#create kubeadm config file
wget https://docs.projectcalico.org/manifests/calico.yaml
kubeadm config print init-defaults | tee ClusterConfiguration.yaml

sudo kubeadm init --config=ClusterConfiguration.yaml 
sudo kubeadm init --cri-socket /run/containerd.sock

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id u):$(id -g) $HOME/.kube/config
kubectl apply -f calico.yaml

echo "For this Stack, you will use $IP IP Address"
#####################################################################################################################