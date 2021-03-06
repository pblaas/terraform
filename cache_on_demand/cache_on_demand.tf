provider "openstack" {
  user_name   = "YOUR_USERNAME"
  tenant_name = "YOUR_PROJECTNAME"
  auth_url    = "https://identity.openstack.cloudvps.com:443/v3"
}

resource "openstack_compute_keypair_v2" "jenkins-deployer-key" {
  name   = "jenkins-deployer-key"
  public_key = "SSHRSA_PUBLICKEY"
}

resource "openstack_compute_instance_v2" "YOUR_VMNAME" {
  name      = "YOUR_VMNAME"
  availability_zone = "AMS-EQ1"
  image_id  = "9832f6ea-f5c8-4fbd-90ac-1c17bc76e7ee"
  flavor_id = "2004" 
  key_pair  = "jenkins-deployer-key"
  security_groups = ["Allow-All"]

  provisioner "file" {       
    source      = "cert.pem" 
    destination = "/root/cert.pem" 
  }       

  provisioner "file" {
    source      = "bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/root/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /root/bootstrap.sh",
      "/root/bootstrap.sh"
    ]
  }

  network {
    uuid = "03708997-16bd-43d8-9b51-24e3b3d6a759"
    name = "net-public"
  }

}

