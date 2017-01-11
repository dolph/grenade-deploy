#!/bin/bash
set -ex

# Drop the public key into place.
mkdir -p ~/.ssh/
touch ~/.ssh/id_rsa.pub
chmod 0644 ~/.ssh/id_rsa.pub
echo $1 > ~/.ssh/id_rsa.pub

# This is really screwy, but something about the way Concourse CI handles line
# breaks from YML files causes them to be replaced by spaces by the time we get
# here, so we have to manually fix things up.
touch ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa
echo '-----BEGIN RSA PRIVATE KEY-----' > ~/.ssh/id_rsa
echo $2 | tr " " "\n" >> ~/.ssh/id_rsa
echo '-----END RSA PRIVATE KEY-----' >> ~/.ssh/id_rsa

apt-get update
apt-get install -y \
    curl \
    ssh \
    ;

# Download the rack client if it's not already.
if [ ! -f rack ]; then
    echo "Downloading the rack client..."
    case "$(uname -s)" in
    Linux)
        # Linux 64-bit binary
        curl https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.2/Linux/amd64/rack > rack
        ;;
    Darwin)
        # OS X 64-bit binary
        curl https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.2/Darwin/amd64/rack > rack
        ;;
    esac

    chmod +x rack
fi

# Configure rack client if it's not already
if [ $# -eq 5 ]; then
    echo "Configuring the rack client..."
    mkdir ~/.rack/
    echo "username = $3" > ~/.rack/config
    echo "api-key = $4" >> ~/.rack/config
    echo "region = $5" >> ~/.rack/config
elif [ ! -f ~/.rack/config ]; then
    echo "Configuring the rack client (interactive)..."
    ./rack configure
fi

echo "Deleting existing grenade server (if one exists)..."
./rack servers instance delete --name="grenade" || true

echo "Provisioning server..."
./rack servers instance create \
    --name="grenade" \
    --image-name="Ubuntu 16.04 LTS (Xenial Xerus) (PVHVM)" \
    --flavor-name="8 GB Performance" \
    --keypair="ci" \
    --wait-for-completion;

echo "Attempting to SSH into $IP..."
while true; do
    IP=`./rack servers instance list --name="grenade" --fields=publicipv4 --status=ACTIVE | sed -n 2p`
    if ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'whoami'; then
        break
    fi
    sleep 1.0
done

echo "Bootstrapping devstack @ $IP..."
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'apt-get update'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'apt-get install git'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'adduser --disabled-password --gecos "" stack'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'mkdir -p /opt/stack/'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'chown stack:stack /opt/stack/'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'cd /opt/stack; sudo -H -u stack git clone https://git.openstack.org/openstack-dev/devstack'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'sudo -H -u stack cat <<EOT >> /opt/stack/devstack/local.conf
[[local|localrc]]
ADMIN_PASSWORD=secret
DATABASE_PASSWORD=secret
RABBIT_PASSWORD=secret
SERVICE_PASSWORD=secret
EOT'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'cd /opt/stack/devstack; sudo -H -u stack ./stack.sh'
