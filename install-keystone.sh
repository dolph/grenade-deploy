#!/bin/bash
set -ex

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done

# Ensure python 2.7 is installed.
apt-get install -y \
    python2.7 \
    ;

# Install pip from source.
curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py \
    | python2.7

cd /opt/openstack-ansible-os_keystone

# Install bindep to discover binary deps.
pip install bindep tox
export DEBIAN_FRONTEND=noninteractive
apt-get install -y $(bindep -b -f bindep.txt test || true)

tox -e upgrade
