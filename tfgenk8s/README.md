## Terraform Generator - Kubernetes

This project consists of the python script tfgenk8s.py and four template files. Through the Jinja2 templating engine a Terraform file is generated which can be used to spin up a kubernetes cluster. The cloudinit files which are injected in the Terraformed nodes are generated by https://github.com/pblaas/cloudinit_generator. tfgenk8s.py will perform this task automaticly for you.

### Dependencies

* Terraform
* Python2.x
* Jinja2 python module
* git
* Openstack 'allow-all' security group for SNAT ports. 

### Usage
```
usage: tfgenk8s.py [-h] [--username USERNAME] [--projectname PROJECTNAME]
                   [--clustername CLUSTERNAME] [--subnetcidr SUBNETCIDR]
                   [--calicocidr CALICOCIDR] [--nodes NODES]
                   [--imageflavor IMAGEFLAVOR] [--dnsserver DNSSERVER]
                   [--cloudprovider CLOUDPROVIDER] [--k8sver K8SVER]
                   [--flannelver FLANNELVER] [--netoverlay NETOVERLAY]
                   [--gitbranch GITBRANCH] [--sshkey1 SSHKEY1]
                   [--sshkey2 SSHKEY2]
                   keypair floatingip1 floatingip2 corepassword

positional arguments:
  keypair               Keypair ID
  floatingip1           Floatingip 1 for API calls
  floatingip2           Floatingip 2 for public access to cluster
  corepassword          Password to authenticate with core user

optional arguments:
  -h, --help            show this help message and exit
  --username USERNAME   Openstack username - (OS_USERNAME environment
                        variable)
  --projectname PROJECTNAME
                        Openstack project Name - (OS_TENANT_NAME environment
                        variable)
  --clustername CLUSTERNAME
                        Clustername - (k8scluster)
  --subnetcidr SUBNETCIDR
                        Private subnet CIDR - (192.168.3.0/24)
  --calicocidr CALICOCIDR
                        Calico subnet CIDR - (10.244.0.0/16)
  --nodes NODES         Number of k8s nodes - (3)
  --imageflavor IMAGEFLAVOR
                        Image flavor ID - (2008)
  --dnsserver DNSSERVER
                        DNS server - (8.8.8.8)
  --cloudprovider CLOUDPROVIDER
                        Cloud provider support - (openstack)
  --k8sver K8SVER       Hyperkube version - (v1.7.9_coreos.0)
  --flannelver FLANNELVER
                        Flannel image version - (v0.8.0)
  --netoverlay NETOVERLAY
                        Network overlay - (flannel)
  --gitbranch GITBRANCH
                        Cloudinit_generator branch - (master)
  --sshkey1 SSHKEY1     SSH key for remote access
  --sshkey2 SSHKEY2     SSH key for remote access
```

### Caveats
* Single master k8s setup
* First three nodes are part of etcd2 cluster
* etcd2 cluster inside k8s cluster
