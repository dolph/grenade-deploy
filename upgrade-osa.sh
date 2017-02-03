#!/bin/bash
set -ex

cd /opt/openstack-ansible

# Find the latest tag.
git checkout master
git checkout `git describe --abbrev=0`

export I_REALLY_KNOW_WHAT_I_AM_DOING=true
bash scripts/run-upgrade.sh
