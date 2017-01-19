#!/bin/bash
set -ex

GRENADE_BRANCH=$1

apt-get update
apt-get install -y git
adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
mkdir -p /opt/stack/
chown stack:stack /opt/stack/
cd /opt/stack; sudo -H -u stack git clone https://github.com/osic/devstack-lxc.git
cd /opt/stack/devstack-lxc; sudo -H -u stack ./install-multinode.sh
cd /opt/stack/devstack-lxc; sudo -H -u stack ./teardown.sh
