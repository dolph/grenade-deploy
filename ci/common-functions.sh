#!/bin/bash
set -ex

function bootstrap {
    apt-get update
}

function bootstrap_rack {
    rack_username=$1
    rack_api_key=$2
    rack_region=$3

    apt-get install -y curl

    # Download the 64-bit rack client binary
    curl https://ec4a542dbf90c03b9f75-b342aba65414ad802720b41e8159cf45.ssl.cf5.rackcdn.com/1.2/Linux/amd64/rack > /usr/local/bin/rack
    chmod +x /usr/local/bin/rack

    # Configure rack client
    mkdir ~/.rack/
    echo "username = $rack_username" > ~/.rack/config
    echo "api-key = $rack_api_key" >> ~/.rack/config
    echo "region = $rack_region" >> ~/.rack/config
}

function bootstrap_ssh {
    ssh_public_key=$1
    ssh_private_key_body=$2

    apt-get install -y ssh rsync

    # Drop the public key into place.
    mkdir -p ~/.ssh/
    touch ~/.ssh/id_rsa.pub
    chmod 0644 ~/.ssh/id_rsa.pub
    echo $SSH_PUBLIC_KEY > ~/.ssh/id_rsa.pub

    # This is really screwy, but something about the way Concourse CI handles
    # line breaks from YML files causes them to be replaced by spaces by the
    # time we get here, so we have to manually fix things up.
    touch ~/.ssh/id_rsa
    chmod 0600 ~/.ssh/id_rsa
    echo '-----BEGIN RSA PRIVATE KEY-----' > ~/.ssh/id_rsa
    echo $SSH_PRIVATE_KEY_BODY | tr " " "\n" >> ~/.ssh/id_rsa
    echo '-----END RSA PRIVATE KEY-----' >> ~/.ssh/id_rsa
}

function get_field {
    instance_name=$1
    field_name=$2

    echo $(rack servers instance list --name="$instance_name" --fields="$field_name" --status=ACTIVE | sed -n 2p)
}

function get_public_ip {
    instance_name=$1

    echo $(get_field $instance_name publicipv4)
}

function get_private_ip {
    instance_name=$1

    echo $(get_field $instance_name privateipv4)
}

function provision_instance {
    instance_name=$1
    image_name=$2

    rack servers instance create \
        --name="$instance_name" \
        --image-name="$image_name" \
        --flavor-name="8 GB Performance" \
        --keypair="ci" \
        --wait-for-completion;

    # Wait until we have an IP.
    while true; do
        public_ip=$(get_public_ip $instance_name)

        # If we have an IP...
        if [[ ! -z "${public_ip// }" ]]; then
            break
        fi

        sleep 1.0
    done

    wait_for_ssh $public_ip

    # Keyscan the new host.
    touch ~/.ssh/known_hosts
    ssh-keyscan -H $public_ip >> ~/.ssh/known_hosts
}

function wait_for_ssh {
    public_ip=$1

    # Wait until we can SSH into the instance...
    while true; do
        if ssh -o BatchMode=yes -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$public_ip 'whoami'; then
            break
        fi

        sleep 1.0
    done
}

function upgrade_instance {
    public_ip=$1

    ssh \
        -o BatchMode=yes \
        root@$public_ip 'for i in `seq 1 10`; do apt-get update && break || sleep 15; done; apt-get upgrade -y && apt-get dist-upgrade -y && shutdown --reboot 1'

    sleep 10
    wait_for_ssh $public_ip
}

function delete_instance {
    instance_name=$1

    rack servers instance delete --name="$instance_name" || true
}
