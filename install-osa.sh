#!/bin/bash
set -ex

BRANCH=${1:-master}

PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done
apt-get install -y git

cd /opt/openstack-ansible
git checkout $BRANCH
export BOOTSTRAP_OPTS="bootstrap_host_ubuntu_repo=http://mirror.rackspace.com/ubuntu"
export ANSIBLE_ROLE_FETCH_MODE=git-clone
scripts/bootstrap-ansible.sh
scripts/bootstrap-aio.sh
scripts/run-playbooks.sh
