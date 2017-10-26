#!/bin/bash
# Master Bootstrap
apt-get update
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common \
  jq \
  etcd

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

echo '
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://0.0.0.0:2380,http://0.0.0.0:7001"
ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
' >> /etc/default/etcd

## need to write workerinfo and master info to etcd cluster.
service etcd restart

#initialize docker swarm.
docker swarm init

#write worker and manager tokens to etcd.
etcdctl set worker-token $(docker swarm join-token worker|grep token|awk '{ print $5 }')
etcdctl set manager-token $(docker swarm join-token manager|grep token|awk '{ print $5 }')

echo '
 ___   ___   ___ _  _____ ___  _____      ___   ___ __  __ 
|   \ / _ \ / __| |/ / __| _ \/ __\ \    / /_\ | _ \  \/  |
| |) | (_) | (__| ' <| _||   /\__ \\ \/\/ / _ \|   / |\/| |
|___/ \___/ \___|_|\_\___|_|_\|___/ \_/\_/_/ \_\_|_\_|  |_|
                                                           
' > /etc/motd


