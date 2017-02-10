#!/bin/bash
set -ex

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done

apt-get install -y \
    build-essential \
    git-core \
    libssl-dev \
    libffi-dev \
    python2.7 \
    python-dev \
    python-ndg-httpsclient \
    gzip \
    libpq-dev \
    libxml2-dev \
    libxslt-dev \
    ;

curl --silent --show-error --retry 5 https://bootstrap.pypa.io/get-pip.py \
    | python

pip install bindep tox
BINDEP_PKGS=$(bindep -b -f bindep.txt test || true)
DEBIAN_FRONTEND=noninteractive \
    apt-get install $BINDEP_PKGS

cd /opt/openstack-ansible
export BOOTSTRAP_OPTS="bootstrap_host_ubuntu_repo=http://mirror.rackspace.com/ubuntu"
export ANSIBLE_ROLE_FETCH_MODE=git-clone
bash scripts/bootstrap-ansible.sh

cd /opt/openstack-ansible-os_keystone
tox -e upgrade
