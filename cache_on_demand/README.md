#### Caching on demand with SSL support - Terraform configuration

##### Dependencies

* terraform client
* openstack credentials
* Openstack variables need to be loaded
* ssh private key needs to be loaded

##### Usage

* update the cache_on_demand.tf terraform config file with your personal settings.
  *  user_name
  * tenant_name
  * key_pair

* Update the the docker-compose.yml to reflect your destination webserver HOST.DOMAIN.LTD.

* Concat the SSL private key and SSL certificate into a file called cert.pem

* Initiate the terraform.
```
terraform plan
```
```
terraform apply
```

Depending on the assigned security group the instance should be avaiable on atleast port 80 and 443 TCP.
 
