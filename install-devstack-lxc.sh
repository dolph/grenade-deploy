#!/bin/bash
set -ex

apt-get update
apt-get install -y git
adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
cd /home/stack;
sudo -H -u stack git clone https://github.com/osic/devstack-lxc.git
cd /home/stack/devstack-lxc;
sudo -H -u stack ./install-multinode.sh
sudo -H -u stack ./teardown.sh
