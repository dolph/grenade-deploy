#!/bin/bash
set -ex

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done
apt-get install -y git python-tox
adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

cd /home/stack
sudo -H -u stack git clone https://github.com/osic/devstack-lxc.git
cd /home/stack/devstack-lxc
sudo -H -u stack sudo ./install-multinode.sh

cd /home/stack
sudo -H -u stack git clone https://github.com/openstack/tempest.git
cd /home/stack/tempest
tox -esmoke

cd /home/stack/devstack-lxc
sudo -H -u stack sudo ./teardown.sh
