#!/bin/bash
set -ex

GRENADE_BRANCH=$1

apt-get update
apt-get install -y git
adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
mkdir -p /opt/stack/
chown stack:stack /opt/stack/

cd /opt/stack;

sudo -H -u stack git clone https://git.openstack.org/openstack-dev/grenade
sudo -H -u stack cat <<EOT >> /opt/stack/grenade/devstack.localrc
# Disable heat.
disable_service h-api h-api-cfn h-api-cw h-eng heat

# Switch to neutron.
disable_service n-net
enable_service q-agt q-dhcp q-l3 q-meta q-svc quantum

Q_USE_DEBUG_COMMAND=True
NETWORK_GATEWAY=192.168.0.1
FIXED_RANGE=192.168.0.0/20
FLOATING_RANGE=172.24.5.0/24
PUBLIC_NETWORK_GATEWAY=172.24.5.1

USE_SCREEN=False
EOT

cd /opt/stack/grenade;

sudo -H -u stack git checkout $GRENADE_BRANCH
sudo -H -u stack ./grenade.sh
shutdown -h now
