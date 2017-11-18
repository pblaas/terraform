provider "openstack" {
  user_name   = "${var.username}"
  tenant_name = "${var.tenantname}"
  auth_url    = "https://identity.openstack.cloudvps.com:443/v3"
}


resource "openstack_networking_network_v2" "network_nodelb" {
  name           = "network_nodelb"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "subnet_nodelb_cluster" {
  name       = "subnet_nodelb_cluster"
  network_id = "${openstack_networking_network_v2.network_nodelb.id}"
  cidr       = "192.168.3.0/24"
  ip_version = 4
}

resource "openstack_networking_router_v2" "nodelb_cluster_router1" {
  name             = "nodelb_cluster_router1"
  external_gateway = "f9c73cd5-9e7b-4bfd-89eb-c2f4f584c326"
}

resource "openstack_networking_router_interface_v2" "nodelb_cluster_router_interface1" {
  router_id = "${openstack_networking_router_v2.nodelb_cluster_router1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_nodelb_cluster.id}"
}

resource "openstack_compute_secgroup_v2" "secgroup_nodelb_set1" {
  name        = "secgroup_nodelb_set1"
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

resource "openstack_compute_secgroup_v2" "secgroup_nodelb_set2" {
  name        = "secgroup_nodelb_set2"
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

resource "openstack_compute_secgroup_v2" "secgroup_nodelb_set3" {
  name        = "secgroup_nodelb_set3"
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


resource "openstack_networking_port_v2" "nodelb_cluster_port_1" {
  name               = "nodelb_cluster_port_1"
  network_id         = "${openstack_networking_network_v2.network_nodelb.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_nodelb_set1.id}","${openstack_compute_secgroup_v2.secgroup_nodelb_set2.id}"]

  fixed_ip {
    "subnet_id"  = "${openstack_networking_subnet_v2.subnet_nodelb_cluster.id}"
    "ip_address" = "192.168.3.10"
  }
}

resource "openstack_networking_port_v2" "nodelb_cluster_port_2" {
  name               = "nodelb_cluster_port_2"
  network_id         = "${openstack_networking_network_v2.network_nodelb.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_nodelb_set3.id}"]

  fixed_ip {
    "subnet_id"  = "${openstack_networking_subnet_v2.subnet_nodelb_cluster.id}"
    "ip_address" = "192.168.3.11"
  }
}

resource "openstack_networking_port_v2" "nodelb_cluster_port_3" {
  name               = "nodelb_cluster_port_3"
  network_id         = "${openstack_networking_network_v2.network_nodelb.id}"
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.secgroup_nodelb_set1.id}","${openstack_compute_secgroup_v2.secgroup_nodelb_set2.id}"]

  fixed_ip {
    "subnet_id"  = "${openstack_networking_subnet_v2.subnet_nodelb_cluster.id}"
    "ip_address" = "192.168.3.12"
  }
}

resource "openstack_compute_instance_v2" "nodelb-node1" {
  name      = "nodelb-node1"
  availability_zone = "AMS-EQ1"
  image_name  = "Ubuntu 16.04 (LTS)"
  flavor_id = "1002"
  key_pair  = "${var.keypair}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_nodelb_set1.name}","${openstack_compute_secgroup_v2.secgroup_nodelb_set2.name}"]
  user_data = "${file("bootstrap.sh")}"

  network {
    name = "${openstack_networking_network_v2.network_nodelb.name}"
    port = "${openstack_networking_port_v2.nodelb_cluster_port_1.id}"
  }
}

resource "openstack_compute_instance_v2" "nodelb-node2" {
  name      = "nodelb-node2"
  availability_zone = "AMS-EQ1"
  image_name  = "Ubuntu 16.04 (LTS)"
  flavor_id = "1002"
  key_pair  = "${var.keypair}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_nodelb_set3.name}"]
  user_data = "${file("bootstrap.sh")}"

  network {
    name = "${openstack_networking_network_v2.network_nodelb.name}"
    port = "${openstack_networking_port_v2.nodelb_cluster_port_2.id}"
  }
}

resource "openstack_compute_instance_v2" "nodelb-node3" {
  name      = "nodelb-node3"
  availability_zone = "AMS-EQ1"
  image_name  = "Ubuntu 16.04 (LTS)"
  flavor_id = "1002"
  key_pair  = "${var.keypair}"
  security_groups = ["${openstack_compute_secgroup_v2.secgroup_nodelb_set1.name}","${openstack_compute_secgroup_v2.secgroup_nodelb_set2.name}"]
  user_data = "${file("bootstrap.sh")}"

  network {
    name = "${openstack_networking_network_v2.network_nodelb.name}"
    port = "${openstack_networking_port_v2.nodelb_cluster_port_3.id}"
  }
}

resource "openstack_networking_floatingip_v2" "fip_c3_f1" {
  pool = "floating"
}

resource "openstack_compute_floatingip_associate_v2" "fip_c3_f1" {
  instance_id = "${openstack_compute_instance_v2.nodelb-node1.id}"
  floating_ip = "${openstack_networking_floatingip_v2.fip_c3_f1.address}"
}

resource "openstack_lb_monitor_v2" "monitor_1" {
  pool_id     = "${openstack_lb_pool_v2.pool_1.id}"
  type        = "PING"
  delay       = 20
  timeout     = 10
  max_retries = 5
}

resource "openstack_lb_loadbalancer_v2" "lb_1" {
  name          = "lb1"
  vip_subnet_id = "${openstack_networking_subnet_v2.subnet_nodelb_cluster.id}"
}

resource "openstack_lb_listener_v2" "listener_1" {
  name            = "listener_1"
  protocol        = "TCP"
  protocol_port   =  80
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.lb_1.id}"
}

resource "openstack_lb_pool_v2" "pool_1" {
  name        = "pool_1"
  protocol    = "TCP"
  lb_method   = "ROUND_ROBIN"
  listener_id = "${openstack_lb_listener_v2.listener_1.id}"
}

resource "openstack_lb_member_v2" "member_1" {
  pool_id = "${openstack_lb_pool_v2.pool_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_nodelb_cluster.id}"
  address = "${openstack_compute_instance_v2.nodelb-node1.access_ip_v4}"
  protocol_port    = 80
}

resource "openstack_lb_member_v2" "member_2" {
  pool_id = "${openstack_lb_pool_v2.pool_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_nodelb_cluster.id}"
  address = "${openstack_compute_instance_v2.nodelb-node2.access_ip_v4}"
  protocol_port    = 80
}

resource "openstack_lb_member_v2" "member_3" {
  pool_id = "${openstack_lb_pool_v2.pool_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_nodelb_cluster.id}"
  address = "${openstack_compute_instance_v2.nodelb-node3.access_ip_v4}"
  protocol_port    = 80
}
