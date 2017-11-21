### terraform
Terraform configurations


##### Configurations

* cache_on_demand - Hitch and Varnish caching solution
* tfgenk8s.py - Python script to generate Terraform file for a kubernetes cluster.
* tfgen2k8s.py - Second version of Python script to generate Terraformed k8s cluster. This version is able to create HA master setup.
* tfgenswarm.py - Python script to generate Terraform file for a swarm cluster.
* lbaas_example - Terraform config file to create 3 node nginx with OpenStack loadbalancer v2 resources (lbaas)


##### Docker

All required tools to run these configurations are included in the following container image:
```
docker pull pblaas/openstack-cli
```
https://hub.docker.com/r/pblaas/openstack-cli/


