#!/bin/bash

if [ -f /home/vagrant/.ssh/authorized_keys ]; then
  chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
  chmod 600 /home/vagrant/.ssh/authorized_keys
else
  echo "⚠️  authorized_keys not found."
  exit 1
fi