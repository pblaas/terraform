#!/bin/bash
#June 18 2017 Patrick Blaas <Patrick@kite4fun.nl>
# Terraform, cloudinit_generator wrapper script to initiate a Single node Kubernetes cluster.

IFS=$'\n\t'
#create list of main cluster ips.
echo Downloading cloudinit_generator.
git clone https://github.com/pblaas/cloudinit_generator.git

MASTER_HOST_IP=$(cat k8s_cluster_ips.txt |awk '{ print $1 }')
MASTER_HOST_FQDN=$(cat k8s_cluster_ips.txt |awk '{ print $1 }')
MASTER_HOST_GW=$(cat k8s_cluster_ips.txt |awk '{ print $1 }'|cut -d. -f1-3).1
WORKER_GW=$(cat k8s_cluster_ips.txt |awk '{ print $1 }'|cut -d. -f1-3).1
WORKER_IP1=$(cat k8s_cluster_ips.txt |awk '{ print $2 }')
WORKER_IP2=$(cat k8s_cluster_ips.txt |awk '{ print $3 }')
WORKER_HOSTS="($WORKER_IP1 $WORKER_IP2)"
FLOATING_IP=$(cat k8s_floating_ip.txt)
K8S_VER=v1.7.0_coreos.0
K8S_SERVICE_IP=10.3.0.1
DNSSERVER=8.8.8.8
CLUSTER_DNS=10.3.0.10
SERVICE_CLUSTER_IP_RANGE=10.3.0.0/24
ETCD_ENDPOINTS_URLS=http://$MASTER_HOST_IP:2379,http://$WORKER_IP1:2379,http://$WORKER_IP2:2379
USER_CORE_PASSWORD="s@iling"
USER_CORE_KEY1="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQBiwg/NhHsLYvzgnu348INH6YnZAZlKkTuW3bjJjJoy9FSc8hxJzl4vqe2XAK/7EtVCV3YaCA31/pB6wzv3/GKztZqZlqqOFkXsJWeZSekhb4Co2KIZMbIjzWlT/rSpsy3r/wJMeZbsSWV0UaqdxvZHE8yG/NIwPFliSKz5NxBm0f1ONlJTZ79FOlbl//EAAuqcQijJ1VzfNHSmFll5nD2hOib2+WpZ7KbWKVZHcfXlqqmNu1qna1r6K9ZKZScZCJp4LspZ1nJantZ/osBz7YTxt7h/XGgO5PB/SlPH9H9xRh0NIQCQD5h8nDjxRvC6yUlL1pf/z28tppMHvVwFiVvn"
USER_CORE_KEY2="ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQBiwg/NhHsLYvzgnu348INH6YnZAZlKkTuW3bjJjJoy9FSc8hxJzl4vqe2XAK/7EtVCV3YaCA31/pB6wzv3/GKztZqZlqqOFkXsJWeZSekhb4Co2KIZMbIjzWlT/rSpsy3r/wJMeZbsSWV0UaqdxvZHE8yG/NIwPFliSKz5NxBm0f1ONlJTZ79FOlbl//EAAuqcQijJ1VzfNHSmFll5nD2hOib2+WpZ7KbWKVZHcfXlqqmNu1qna1r6K9ZKZScZCJp4LspZ1nJantZ/osBz7YTxt7h/XGgO5PB/SlPH9H9xRh0NIQCQD5h8nDjxRvC6yUlL1pf/z28tppMHvVwFiVvn"

#generate conf.env
echo MASTER_HOST_IP=$MASTER_HOST_IP > cloudinit_generator/config.env
echo MASTER_HOST_FQDN=$MASTER_HOST_FQDN >> cloudinit_generator/config.env
echo MASTER_HOST_GW=$MASTER_HOST_GW >> cloudinit_generator/config.env
echo WORKER_GW=$WORKER_GW >> cloudinit_generator/config.env
echo WORKER_IP1=$WORKER_IP1 >> cloudinit_generator/config.env
echo WORKER_IP2=$WORKER_IP2 >> cloudinit_generator/config.env
echo FLOATING_IP=$FLOATING_IP >> cloudinit_generator/config.env
echo WORKER_HOSTS=$WORKER_HOSTS >> cloudinit_generator/config.env
echo K8S_VER=$K8S_VER >> cloudinit_generator/config.env
echo K8S_SERVICE_IP=$K8S_SERVICE_IP >> cloudinit_generator/config.env
echo DNSSERVER=$DNSSERVER >> cloudinit_generator/config.env
echo CLUSTER_DNS=$CLUSTER_DNS >> cloudinit_generator/config.env
echo SERVICE_CLUSTER_IP_RANGE=$SERVICE_CLUSTER_IP_RANGE >> cloudinit_generator/config.env
echo ETCD_ENDPOINTS_URLS=$ETCD_ENDPOINTS_URLS >> cloudinit_generator/config.env
echo USER_CORE_PASSWORD=\"$USER_CORE_PASSWORD\" >> cloudinit_generator/config.env
echo USER_CORE_KEY1=\"$USER_CORE_KEY1\" >> cloudinit_generator/config.env
echo USER_CORE_KEY2=\"$USER_CORE_KEY2\" >> cloudinit_generator/config.env

cd cloudinit_generator 
echo YES | ./create_cloudinit.sh
cd -

terraform plan && terraform apply

echo You can now run:
echo kubectl config set-cluster $MASTER_HOST_IP-cluster --server=https://$(cat k8s_floating_ip.txt) --certificate-authority=./cloudinit_generator/set/ca.pem
echo echo kubectl config set-credentials $MASTER_HOST_IP-admin --certificate-authority=./cloudinit_generator/set/ca.pem --client-key=./cloudinit_generator/set/admin-key.pem --client-certificate=./cloudinit_generator/set/admin.pem
echo kubectl config set-context $MASTER_HOST_IP-admin --cluster=$MASTER_HOST_IP-cluster --user=$MASTER_HOST_IP-admin
echo kubectl config use-context $MASTER_HOST_IP-admin

echo "kubectl config set-cluster $MASTER_HOST_IP-cluster --server=https://$(cat k8s_floating_ip.txt) --certificate-authority=./cloudinit_generator/set/ca.pem" > kubeconfig.sh
echo "kubectl config set-credentials $MASTER_HOST_IP-admin --certificate-authority=./cloudinit_generator/set/ca.pem --client-key=./cloudinit_generator/set/admin-key.pem --client-certificate=./cloudinit_generator/set/admin.pem" >> kubeconfig.sh
echo "kubectl config set-context $MASTER_HOST_IP-admin --cluster=$MASTER_HOST_IP-cluster --user=$MASTER_HOST_IP-admin" >> kubeconfig.sh                                                   
echo "kubectl config use-context $MASTER_HOST_IP-admin" >> kubeconfig.sh

echo Or run \"sh kubeconfig.sh\" to load the kubeconfig.

echo It will take about 3-5 minutes before the instance is available through API because k8s needs to bootstrap the components.
echo Please be patient.

for i in `openstack port list|grep 100.64|awk '{ print $2 }'`; do  openstack port set --security-group allow-all $i; done
