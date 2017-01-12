#!/bin/bash
set -ex

SSH_PUBLIC_KEY=$1
SSH_PRIVATE_KEY_BODY=$2
GRENADE_BRANCH=$3
RACK_USERNAME=$4
RACK_API_KEY=$5
RACK_REGION=$6

# Drop the public key into place.
mkdir -p ~/.ssh/
touch ~/.ssh/id_rsa.pub
chmod 0644 ~/.ssh/id_rsa.pub
echo $SSH_PUBLIC_KEY > ~/.ssh/id_rsa.pub

# This is really screwy, but something about the way Concourse CI handles line
# breaks from YML files causes them to be replaced by spaces by the time we get
# here, so we have to manually fix things up.
touch ~/.ssh/id_rsa
chmod 0600 ~/.ssh/id_rsa
echo '-----BEGIN RSA PRIVATE KEY-----' > ~/.ssh/id_rsa
echo $SSH_PRIVATE_KEY_BODY | tr " " "\n" >> ~/.ssh/id_rsa
echo '-----END RSA PRIVATE KEY-----' >> ~/.ssh/id_rsa

ls -la ~/.ssh/
cat ~/.ssh/id_rsa.pub
cat ~/.ssh/id_rsa

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
if [ $# -eq 6 ]; then
    echo "Configuring the rack client..."
    mkdir ~/.rack/
    echo "username = $RACK_USERNAME" > ~/.rack/config
    echo "api-key = $RACK_API_KEY" >> ~/.rack/config
    echo "region = $RACK_REGION" >> ~/.rack/config
elif [ ! -f ~/.rack/config ]; then
    echo "Configuring the rack client (interactive)..."
    ./rack configure
fi

INSTANCE_NUMBER=`shuf -i 100000-999999 -n 1`
INSTANCE_NAME="grenade-$INSTANCE_NUMBER"

# Always cleanup instances when the script exits.
function cleanup {
    echo "Deleting existing grenade server (if one exists)..."
    ./rack servers instance delete --name="$INSTANCE_NAME" || true
}
trap cleanup EXIT

echo "Provisioning server..."
./rack servers instance create \
    --name="$INSTANCE_NAME" \
    --image-name="Ubuntu 14.04 LTS (Trusty Tahr) (PVHVM)" \
    --flavor-name="8 GB Performance" \
    --keypair="ci" \
    --wait-for-completion;

echo "Attempting to SSH into $IP..."
while true; do
    IP=`./rack servers instance list --name="$INSTANCE_NAME" --fields=publicipv4 --status=ACTIVE | sed -n 2p`
    if ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'whoami'; then
        break
    fi
    sleep 1.0
done

echo "Bootstrapping devstack @ $IP..."
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'apt-get update'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'apt-get install -y git'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'adduser --disabled-password --gecos "" stack'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'echo "stack ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'mkdir -p /opt/stack/'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'chown stack:stack /opt/stack/'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'cd /opt/stack; sudo -H -u stack git clone https://git.openstack.org/openstack-dev/grenade'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'sudo -H -u stack cat <<EOT >> /opt/stack/grenade/devstack.localrc
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
EOT'
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP "cd /opt/stack/grenade; sudo -H -u stack git checkout $GRENADE_BRANCH"
ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$IP 'cd /opt/stack/grenade; sudo -H -u stack ./grenade.sh'
