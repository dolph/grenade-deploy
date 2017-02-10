#!/bin/bash
set -ex

export DEBIAN_FRONTEND=noninteractive

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done

# Ensure python 2.7 is installed, because python3 is the default.
apt-get install -y python2.7

# Install pip from source.
curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py \
    | python2.7

cd /opt/openstack-ansible-os_keystone

# Install bindep to discover binary deps.
pip install bindep
apt-get install -y $(bindep -b -f bindep.txt test || true)

# Test upgrades.
pip install tox
tox -e upgrade
