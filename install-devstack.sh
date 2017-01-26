#!/bin/bash
set -ex

PASSWORD=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done
apt-get install -y git
adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
mkdir -p /opt/stack/
mv /opt/devstack/ /opt/stack/
chown --recursive stack:stack /opt/stack/

cd /opt/stack;
sudo -H -u stack cat <<EOT >> /opt/stack/devstack/local.conf
[[local|localrc]]
ADMIN_PASSWORD=$PASSWORD
DATABASE_PASSWORD=$PASSWORD
RABBIT_PASSWORD=$PASSWORD
SERVICE_PASSWORD=$PASSWORD

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

cd /opt/stack/devstack;
sudo -H -u stack bash stack.sh
