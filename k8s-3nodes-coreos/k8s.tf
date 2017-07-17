provider "openstack" {
  user_name   = "username"
  tenant_name = "PROJECT NAME"
  auth_url    = "https://identity.openstack.cloudvps.com:443/v3"
}


resource "openstack_networking_network_v2" "network_1" {
  name           = "network_1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_k8s_cluster3" {
  name       = "subnet_k8s_cluster3"
  network_id = "${openstack_networking_network_v2.network_1.id}"
  cidr       = "192.168.3.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "k8s_cluster3_router1" {
  name             = "k8s_cluster3_router1"
  external_gateway = "f9c73cd5-9e7b-4bfd-89eb-c2f4f584c326"
}

resource "openstack_networking_router_interface_v2" "k8s_cluster3_router_interface1" {
  router_id = "${openstack_networking_router_v2.k8s_cluster3_router1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_k8s_cluster3.id}"
}

resource "openstack_compute_secgroup_v2" "secgroup_cluster3_set1" {
  name        = "secgroup_cluster3_set1"
  description = "a security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 443
    to_port     = 443
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 8081
    to_port     = 8081
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

}

resource "openstack_compute_secgroup_v2" "secgroup_cluster3_set2" {         
  name        = "secgroup_cluster3_set2"                                    
  description = "Allow internal LAN communication"                              
                                                                
  rule {                                                        
    from_port   = 1                                            
    to_port     = 65535 
    ip_protocol = "tcp"                                
    cidr        = "192.168.3.0/24"                          
  }                                                    

  rule {
    from_port   = 1 
    to_port     = 65535 
    ip_protocol = "udp"
    cidr        = "192.168.3.0/24"
  }
 
  rule {
    from_port   = -1 
    to_port     = -1 
    ip_protocol = "icmp"
    cidr        = "192.168.3.0/24"
  }
}  

resource "openstack_compute_secgroup_v2" "secgroup_cluster3_set3" {                   
  name        = "secgroup_cluster3_set3"                                              
  description = "Allow internal LAN communication"                                    
                                                                                      
  rule {                                                                              
    from_port   = 1                                                                   
    to_port     = 65535                                                               
    ip_protocol = "tcp"                                                               
    cidr        = "0.0.0.0/0"                                                    
  }                                                                                   
                                                                                      
  rule {                                                                              
    from_port   = 1                                                                   
    to_port     = 65535                                                               
    ip_protocol = "udp"                                                               
    cidr        = "0.0.0.0/0"                                                    
  }                                                                                   
                                                                                      
  rule {                                                                              
    from_port   = -1                                                                  
    to_port     = -1                                                                  
    ip_protocol = "icmp"                                                              
    cidr        = "0.0.0.0/0"                                                    
  }                                                                      
} 


resource "openstack_networking_port_v2" "k8s_cluster3_port_1" {
  name               = "k8s_cluster3_port_1"
  network_id         = "${openstack_networking_network_v2.network_1.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_cluster3_set1.id}","${openstack_compute_secgroup_v2.secgroup_cluster3_set2.id}"]

  fixed_ip {
    "subnet_id"  = "${openstack_networking_subnet_v2.subnet_k8s_cluster3.id}"
    "ip_address" = "192.168.3.10"
  }
}

resource "openstack_networking_port_v2" "k8s_cluster3_port_2" {  
  name               = "k8s_cluster3_port_2"                     
  network_id         = "${openstack_networking_network_v2.network_1.id}"
  admin_state_up     = "true"                                           
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_cluster3_set3.id}"]
                                                                                                                          
  fixed_ip {                                                                                                              
    "subnet_id"  = "${openstack_networking_subnet_v2.subnet_k8s_cluster3.id}"                                             
    "ip_address" = "192.168.3.11"                                                                                         
  }                                                                                                                       
} 

resource "openstack_networking_port_v2" "k8s_cluster3_port_3" {  
  name               = "k8s_cluster3_port_3"                     
  network_id         = "${openstack_networking_network_v2.network_1.id}"
  admin_state_up     = "true"                                           
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_cluster3_set1.id}","${openstack_compute_secgroup_v2.secgroup_cluster3_set2.id}"]
                                                                                                                          
  fixed_ip {                                                                                                              
    "subnet_id"  = "${openstack_networking_subnet_v2.subnet_k8s_cluster3.id}"                                             
    "ip_address" = "192.168.3.12"                                                                                         
  }                                                                                                                       
} 

resource "openstack_compute_instance_v2" "k8s-cluster3-node1" {
  name      = "k8s-cluster3-node1"
  availability_zone = "AMS-EQ1"
  image_id  = "75c34677-9436-4df0-9468-6be009c36fc9"
  flavor_id = "2008" 
  key_pair  = "PB_ITE_1"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_cluster3_set1.name}","${openstack_compute_secgroup_v2.secgroup_cluster3_set2.name}"]
  user_data = "${file("cloudinit_generator/set/node_192.168.3.10.yaml")}"

  network {
    port = "${openstack_networking_port_v2.k8s_cluster3_port_1.id}"
  }
}

resource "openstack_compute_instance_v2" "k8s-cluster3-node2" {                                                           
  name      = "k8s-cluster3-node2"                                                                                        
  availability_zone = "AMS-EQ1"                                                                                           
  image_id  = "75c34677-9436-4df0-9468-6be009c36fc9"                                                                      
  flavor_id = "2008"                                                                                                      
  key_pair  = "PB_ITE_1"                                                                                                  
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_cluster3_set3.name}"]                                                  
  user_data = "${file("cloudinit_generator/set/node_192.168.3.11.yaml")}"                                                 
                                                                                                                          
  network {                                                                                                               
    port = "${openstack_networking_port_v2.k8s_cluster3_port_2.id}"                                                       
  }                                                                                                                       
}   

resource "openstack_compute_instance_v2" "k8s-cluster3-node3" {                                                           
  name      = "k8s-cluster3-node3"                                                                                        
  availability_zone = "AMS-EQ1"                                                                                           
  image_id  = "75c34677-9436-4df0-9468-6be009c36fc9"                                                                      
  flavor_id = "2008"                                                                                                      
  key_pair  = "PB_ITE_1"                                                                                                  
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_cluster3_set1.name}","${openstack_compute_secgroup_v2.secgroup_cluster3_set2.name}"]                                                  
  user_data = "${file("cloudinit_generator/set/node_192.168.3.12.yaml")}"                                                 
                                                                                                                          
  network {                                                                                                               
    port = "${openstack_networking_port_v2.k8s_cluster3_port_3.id}"                                                       
  }                                                                                                                       
}   

resource "openstack_networking_floatingip_v2" "fip_c3_f1" {
  pool = "floating" 
  fixed_ip = "83.96.236.21"
}

resource "openstack_networking_floatingip_v2" "fip_c3_f2" {                                                                   
  pool = "floating"                                                                                                       
  fixed_ip = "83.96.236.12"                                                                                               
} 

resource "openstack_compute_floatingip_associate_v2" "fip_c3_f1" {
  instance_id = "${openstack_compute_instance_v2.k8s-cluster3-node1.id}"
  floating_ip = "${openstack_networking_floatingip_v2.fip_c3_f1.fixed_ip}"
}

resource "openstack_compute_floatingip_associate_v2" "fip_c3_f2" {                                                        
  instance_id = "${openstack_compute_instance_v2.k8s-cluster3-node3.id}"                                                  
  floating_ip = "${openstack_networking_floatingip_v2.fip_c3_f2.fixed_ip}"                                                
} 

