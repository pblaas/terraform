## Terraform Generator - Docker Swarm

This project consists of the python script tfgenswarm.py and template files. Through the Jinja2 templating engine a Terraform file is generated which can be used to spin up a swarm cluster.

### Dependencies

* Terraform
* Python2.x
* Jinja2 python module
* git
* Openstack 'allow-all' security group for SNAT ports. 

### Usage

```
usage: tfgenswarm.py [-h] [--username USERNAME] [--projectname PROJECTNAME]
                     [--clustername CLUSTERNAME] [--subnetcidr SUBNETCIDR]
                     [--calicocidr CALICOCIDR] [--managernodes MANAGERNODES]
                     [--workernodes WORKERNODES] [--imageflavor IMAGEFLAVOR]
                     [--cloudprovider CLOUDPROVIDER] [--flannelver FLANNELVER]
                     keypair floatingip1 floatingip2

positional arguments:
  keypair               Keypair ID
  floatingip1           Floatingip 1 for API calls
  floatingip2           Floatingip 2 for public access to cluster

optional arguments:
  -h, --help            show this help message and exit
  --username USERNAME   Openstack username - (OS_USERNAME environment
                        variable)
  --projectname PROJECTNAME
                        Openstack project Name - (OS_TENANT_NAME environment
                        variable)
  --clustername CLUSTERNAME
                        Clustername - (swarmcluster)
  --subnetcidr SUBNETCIDR
                        Private subnet CIDR - (192.168.3.0/24)
  --calicocidr CALICOCIDR
                        Calico subnet CIDR - (10.244.0.0/16)
  --managernodes MANAGERNODES
                        Number of swarm manager nodes - (3)
  --workernodes WORKERNODES
                        Number of swarm workers nodes - (2)
  --imageflavor IMAGEFLAVOR
                        Image flavor ID - (2008)
  --cloudprovider CLOUDPROVIDER
                        Cloud provider support - (openstack)
  --flannelver FLANNELVER
                        Flannel image version - (v0.8.0)
```
