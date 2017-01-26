#!/bin/bash
set -ex

HOST_IP=$1

for i in `seq 1 10`;
do
    apt-get update && break || sleep 15
done
# FIXME: python stuff should be installed by grenade/devstack
apt-get install -y git python3 python3-dev python3-pip
adduser --disabled-password --gecos "" stack
echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Hack to workaround devstack looking for "is_ubuntu"
ln -s /bin/true /usr/local/bin/is_ubuntu

mv /opt/devstack-lxc /home/stack/
chown --recursive stack:stack /home/stack/devstack-lxc/

cd /home/stack/devstack-lxc
sudo -H -u stack sudo ./install-multinode.sh

# Skip smoke tests.
exit

# Smoke test
apt-get install -y \
    build-essential \
    libssl-dev \
    libxml2-dev \
    libxslt-dev \
    python3-dev \
    tox \
    ;
cd /home/stack
sudo -H -u stack git clone https://github.com/openstack/tempest.git
cd /home/stack/tempest
sudo -H -u stack cat <<EOT >> /home/stack/tempest/etc/tempest.conf
[DEFAULT]
debug = true

[auth]
admin_username = admin
admin_project_name = admin
admin_domain_name = Default
admin_password = admin

[identity]
auth_version = v2
uri = http://$HOST_IP:35357/v2.0/
EOT
sudo -H -u stack tox -esmoke

# Tear down
cd /home/stack/devstack-lxc
sudo -H -u stack sudo ./teardown.sh
