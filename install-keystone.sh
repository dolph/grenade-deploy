#!/bin/bash
set -ex

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done

apt-get install -y tox python-dev libpq-dev

cd /opt/openstack-ansible-os_keystone
tox -e upgrade
