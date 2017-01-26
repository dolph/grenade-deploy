#!/bin/bash
set -ex

PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done
apt-get install -y git

cd /opt/openstack-ansible
export BOOTSTRAP_OPTS="bootstrap_host_ubuntu_repo=http://mirror.rackspace.com/ubuntu"
export ANSIBLE_ROLE_FETCH_MODE=git-clone
bash scripts/bootstrap-ansible.sh
echo Bootstrap Ansible: $?
bash scripts/bootstrap-aio.sh
echo Bootstrap AIO: $?
bash scripts/run-playbooks.sh
echo Run playbooks: $?
