#!/bin/bash

sudo apt-get update && apt-get upgrade -y

curl -sfL https://get.k3s.io | sh -s - server \
  --flannel-iface=eth1 \
  --node-ip=$SERVER_IP \
  --write-kubeconfig-mode 644

mkdir -p /vagrant/token
cp /var/lib/rancher/k3s/server/node-token /vagrant/token
