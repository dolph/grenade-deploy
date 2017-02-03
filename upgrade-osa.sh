#!/bin/bash
set -ex

cd /opt/openstack-ansible
git checkout master
export I_REALLY_KNOW_WHAT_I_AM_DOING=true
bash scripts/run-upgrade.sh
