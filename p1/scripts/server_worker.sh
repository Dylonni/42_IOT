#!/bin/bash

sudo apt-get update && apt-get upgrade -y

TOKEN_FILE="/vagrant/token/node-token"

# Searching for Token during 30secs
for i in {1..30}; do
  if [ -f "$TOKEN_FILE" ]; then
    echo "✅ Token has been found."
    break
  fi
  echo "⏳ Waiting for K3S token..."
  sleep 1
done

# If file doesn't exists, stops provisioning
if [ ! -f "$TOKEN_FILE" ]; then
  echo "❌ File $TOKEN_FILE not found. Stopping provisioning."
  exit 1
fi

curl -sfL https://get.k3s.io | sh -s - agent \
  --server "$K3S_URL" \
  --token-file "$TOKEN_FILE" \
  --flannel-iface=eth1 \
  --node-ip="$SERVER_WORKER_IP"
