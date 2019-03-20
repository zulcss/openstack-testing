#!/bin/bash

# Configure for your environment

source ~/standalonerc
export GATEWAY=10.0.0.1
export STANDALONE_HOST=10.0.0.80
export PUBLIC_NETWORK_CIDR=10.0.0.8/24
export PRIVATE_NETWORK_CIDR=10.0.0.0/24
export PUBLIC_NET_START=10.0.0.9
export PUBLIC_NET_END=10.0.0.9
export DNS_SERVER=8.8.8.8

# nova flavor
openstack flavor create --ram 512 --disk 1 --vcpu 1 --public tiny
# basic cirros image
wget https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create cirros --container-format bare --disk-format qcow2 --public --file cirros-0.4.0-x86_64-disk.img
# nova keypair for ssh
ssh-keygen
openstack keypair create --public-key ~/.ssh/id_rsa.pub default

# create basic security group to allow ssh/ping/dns
openstack security group create basic
# allow ssh
openstack security group rule create basic --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0
# allow ping
openstack security group rule create --protocol icmp basic
# allow DNS
openstack security group rule create --protocol udp --dst-port 53:53 basic

openstack network create --external --provider-physical-network datacentre --provider-network-type flat public
openstack network create --internal private
openstack subnet create public-net \
    --subnet-range $PUBLIC_NETWORK_CIDR \
    --no-dhcp \
    --gateway $GATEWAY \
    --allocation-pool start=$PUBLIC_NET_START,end=$PUBLIC_NET_END \
    --network public
openstack subnet create private-net \
    --subnet-range $PRIVATE_NETWORK_CIDR \
    --network private

# create router
# NOTE(aschultz): In this case an IP will be automatically assigned
# out of the allocation pool for the subnet.
openstack router create vrouter
openstack router set vrouter --external-gateway public
openstack router add subnet vrouter private-net

# create floating ip
openstack floating ip create public

