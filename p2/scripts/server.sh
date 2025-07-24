#!/bin/bash

sudo apt-get update && apt-get upgrade -y

curl -sfL https://get.k3s.io | sh -s - server \
  --flannel-iface=eth1 \
  --node-ip=$SERVER_IP \
  --write-kubeconfig-mode 644

mkdir -p /vagrant/token
cp /var/lib/rancher/k3s/server/node-token /vagrant/token

# Adding to etc/hosts in order to make curl tests later on
echo -e "192.168.56.110 app1.com" | sudo tee -a /etc/hosts
echo -e "192.168.56.110 app2.com" | sudo tee -a /etc/hosts
echo -e "192.168.56.110 app3.com" | sudo tee -a /etc/hosts

# Apply configurations for ingress, deployment and service. all inside ../confs
sudo kubectl apply -f /vagrant/confs/deployments.yaml
sudo kubectl apply -f /vagrant/confs/services.yaml
sudo kubectl apply -f /vagrant/confs/ingress.yaml
