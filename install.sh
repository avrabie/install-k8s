#!/bin/sh
sudo apt-get update

#install utils
sudo apt-get install -y vim wget apt-transport-https ca-certificates curl
# turn swap off
sudo swapoff -a
sudo vim /etc/fstab

## Install containerd
wget https://github.com/containerd/containerd/releases/download/v1.7.3/containerd-1.7.3-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local containerd-1.7.3-linux-amd64.tar.gz

sudo mkdir -p /usr/local/lib/systemd/system/
curl https://raw.githubusercontent.com/containerd/containerd/main/containerd.service >> containerd.service
sudo cp containerd.service /usr/local/lib/systemd/system/

systemctl daemon-reload
systemctl enable --now containerd


## Install Runc
wget https://github.com/opencontainers/runc/releases/download/v1.1.9/runc.amd64
install -m 755 runc.amd64 /usr/local/sbin/runc


##Install CNI plugins
wget https://github.com/containernetworking/plugins/releases/download/v1.3.0/cni-plugins-linux-amd64-v1.3.0.tgz
sudo mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.3.0.tgz



mkdir -p /etc/containerd/
containerd config default > /etc/containerd/config.toml
#modify the config.toml
#  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#    SystemdCgroup = true
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

systemctl daemon-reload
systemctl enable --now containerd
sudo systemctl status containerd


# install nerdctl
wget https://github.com/containerd/nerdctl/releases/download/v1.5.0/nerdctl-1.5.0-linux-amd64.tar.gz
sudo tar Cxzvf /usr/local/bin nerdctl-1.5.0-linux-amd64.tar.gz
# sudo nerdctl run -d --name nginx -p 80:80 nginx:alpine

#install buildkit
#https://github.com/moby/buildkit/releases/download/v0.12.1/buildkit-v0.12.1.darwin-amd64.tar.gz
wget https://github.com/moby/buildkit/releases/download/v0.12.1/buildkit-v0.12.1.darwin-amd64.tar.gz
sudo tar Cxzvf /usr/local/bin buildkit-v0.12.1.darwin-amd64.tar.gz



# add ip4tables config, tested for VMs with bridged network
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



## Install kubeadm, kubectl, kubelet
curl -fsSL https://dl.k8s.io/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

