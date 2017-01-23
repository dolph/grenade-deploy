#!/bin/bash
set -ex

SSH_PUBLIC_KEY=$1
SSH_PRIVATE_KEY_BODY=$2
RACK_USERNAME=$3
RACK_API_KEY=$4
RACK_REGION=$5

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bash $DIR/bootstrap-common.sh
bash $DIR/bootstrap-ssh.sh "$SSH_PUBLIC_KEY" "$SSH_PRIVATE_KEY_BODY"
bash $DIR/bootstrap-rack.sh "$RACK_USERNAME" "$RACK_API_KEY" "$RACK_REGION"

INSTANCE_NUMBER=
INSTANCE_NAME="ci-devstack-lxc-`shuf -i 100000-999999 -n 1`"

# Always cleanup instances when the script exits.
function cleanup {
    echo "Deleting existing server (if one exists)..."
    ./rack servers instance delete --name="$INSTANCE_NAME" || true
}
trap cleanup EXIT

echo "Provisioning server..."
./rack servers instance create \
    --name="$INSTANCE_NAME" \
    --image-name="Ubuntu 16.04 LTS (Xenial Xerus) (PVHVM)" \
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

echo "Running devstack-lxc @ $IP..."
ssh \
    -o BatchMode=yes \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    root@$IP 'bash -s' < $DIR/../install-devstack-lxc.sh "$IP"
