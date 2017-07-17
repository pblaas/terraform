### Dependencies

* This configuration is using CloudVPS openstack object ids e.g flavor, image_id.
* git client
* kubectl client
* terraform client
* initialized openstack variables
* "allow-all" security group (for the routers)
* 4 available floating ips

### Setup

To use this Terraform configuration you need to make some small modifications to the files.

##### k8s_setup.sh

You should change the following variables:

* USER_CORE_PASSWORD
* USER_CORE_KEY1
* USER_CORE_KEY2

##### k8s.tf

You should change:

* user_name   = "YOUR USERNAME"
* tenant_name = "PROJECTNAME STRING"
* auth_url    = "https://identity.openstack.cloudvps.com:443/v3"
* key_pair    = "YOUR-KEY-PAIR-object" 


###### Terraform configuration resources

This k8s configuration file will create a least the following resources.

* network 	  = network_1
* subnet  	  = subnet_k8s_cluster3 
* router  	  = k8s_cluster3_router1
* router_interface= k8s_cluster3_router_interface1

### Initialize

After you reconfigured the required settings and made sure all variables are set you can run the following script:
```
sh k8s_setup.sh
```

Setting up the cluster will take about 3-5 minutes. While the cluster is setting up you can run the following generated configuration script to create a kubernetes config file for the new cluster.
```
sh kubeconfig.sh
```

To check when the cluster is available you can run a watch command on the get nodes.
```
watch kubectl get nodes
```


