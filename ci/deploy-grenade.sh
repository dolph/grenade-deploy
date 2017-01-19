#!/bin/bash
set -ex

SSH_PUBLIC_KEY=$1
SSH_PRIVATE_KEY_BODY=$2
GRENADE_BRANCH=$3
RACK_USERNAME=$4
RACK_API_KEY=$5
RACK_REGION=$6

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bash $DIR/bootstrap-common.sh
bash $DIR/bootstrap-ssh.sh $SSH_PUBLIC_KEY $SSH_PRIVATE_KEY_BODY
bash $DIR/bootstrap-rack.sh $RACK_USERNAME $RACK_API_KEY $RACK_REGION

INSTANCE_NUMBER=`shuf -i 100000-999999 -n 1`
INSTANCE_NAME="grenade-$INSTANCE_NUMBER"

# Always cleanup instances when the script exits.
function cleanup {
    echo "Deleting server (if one exists)..."
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

echo "Running grenade @ $IP..."
ssh \
    -o BatchMode=yes \
    -o UserKnownHostsFile=/dev/null \
    -o StrictHostKeyChecking=no \
    root@$IP 'bash -s' < $DIR/../install.sh "$GRENADE_BRANCH"
