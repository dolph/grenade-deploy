#!/bin/bash
set -ex

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done
apt-get install -y git
adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

cd /home/stack
sudo -H -u stack git clone https://github.com/osic/devstack-lxc.git
cd /home/stack/devstack-lxc
sudo -H -u stack sudo ./install-multinode.sh

# Smoke test
apt-get install -y \
    build-essential \
    libxml2-dev \
    libxslt-dev \
    python3-dev \
    tox \
    ;
cd /home/stack
sudo -H -u stack git clone https://github.com/openstack/tempest.git
cd /home/stack/tempest
tox -esmoke

# Tear down
cd /home/stack/devstack-lxc
sudo -H -u stack sudo ./teardown.sh
