#!/usr/bin/env python
__author__ = "Patrick Blaas <patrick@kite4fun.nl>"
__license__ = "MIT"
__version__ = "0.6.2"
__status__ = "Prototype"

import argparse
import os
import subprocess
from jinja2 import Environment, Template, FileSystemLoader

PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_ENVIRONMENT = Environment(
    autoescape=False,
    loader=FileSystemLoader(os.path.join(PATH, '.')),
    trim_blocks=False)


# Testing if environment variables are available.
if not "OS_USERNAME" in os.environ:
    os.environ["OS_USERNAME"]="Default"
if not "OS_PASSWORD" in os.environ:
    os.environ["OS_PASSWORD"]="Default"
if not "OS_TENANT_NAME" in os.environ:
    os.environ["OS_TENANT_NAME"]="Default"
if not "OS_TENANT_ID" in os.environ:
    os.environ["OS_TENANT_ID"]="Default"
if not "OS_REGION_NAME" in os.environ:
    os.environ["OS_REGION_NAME"]="Default"
if not "OS_AUTH_URL" in os.environ:
    os.environ["OS_AUTH_URL"]="Default"

parser = argparse.ArgumentParser()
parser.add_argument("keypair", help="Keypair ID")
parser.add_argument("floatingip1", help="Floatingip 1 for API calls")
parser.add_argument("floatingip2", help="Floatingip 2 for public access to cluster")
parser.add_argument("corepassword", help="Password to authenticate with core user")
parser.add_argument("--username", help="Openstack username - (OS_USERNAME environment variable)", default=os.environ["OS_USERNAME"])
parser.add_argument("--projectname", help="Openstack project Name - (OS_TENANT_NAME environment variable)", default=os.environ["OS_TENANT_NAME"])
parser.add_argument("--clustername", help="Clustername - (k8scluster)", default="k8scluster")
parser.add_argument("--subnetcidr", help="Private subnet CIDR - (192.168.3.0/24)", default="192.168.3.0/24")
parser.add_argument("--calicocidr", help="Calico subnet CIDR - (192.168.48.0/20)", default="192.168.48.0/20")
parser.add_argument("--nodes", help="Number of k8s nodes - (3)", type=int, default=3)
parser.add_argument("--imageflavor", help="Image flavor ID - (2008)", type=int, default=2008)
parser.add_argument("--dnsserver", help="DNS server - (8.8.8.8)", default="8.8.8.8")
parser.add_argument("--cloudprovider", help="Cloud provider support - (openstack)", default="openstack")
parser.add_argument("--k8sver", help="Hyperkube version - (v1.7.6_coreos.0)", default="v1.7.6_coreos.0")
parser.add_argument("--flannelver", help="Flannel image version - (v0.8.0)", default="v0.8.0")
parser.add_argument("--gitbranch", help="Cloudinit_generator branch - (master)", default="master")
parser.add_argument("--sshkey1", help="SSH key for remote access", default="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDlVWpAjJGhyyYnJxmGf6UHSs7mr4he47uovH6noiVyk/qUgreNQH5F/WVGPcRGqtE8Mc1aonDtWSjxxRlT62x3M9rkP4px48dTigUUFPGhhDTeEjyTqKbzedo/17T0CHVjuQkXl9+m/I7AZPmPBaJEb4knkr++B6tnZa65MjA98w==")
parser.add_argument("--sshkey2", help="SSH key for remote access", default="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAAgQDlVWpAjJGhyyYnJxmGf6UHSs7mr4he47uovH6noiVyk/qUgreNQH5F/WVGPcRGqtE8Mc1aonDtWSjxxRlT62x3M9rkP4px48dTigUUFPGhhDTeEjyTqKbzedo/17T0CHVjuQkXl9+m/I7AZPmPBaJEb4knkr++B6tnZa65MjA98w==")
args = parser.parse_args()

template = TEMPLATE_ENVIRONMENT.get_template('k8s.tf.tmpl')
config_template = TEMPLATE_ENVIRONMENT.get_template('config.env.tmpl')
kubeconfig_template = TEMPLATE_ENVIRONMENT.get_template('kubeconfig.sh.tmpl')
cloudconfig_template = TEMPLATE_ENVIRONMENT.get_template('cloud.conf.tmpl')

try:
    if args.nodes < 3:
        raise Exception('Nodes need to be no less then 3.')

    with open('k8s_floating_ip.txt', 'w') as k8sfip:
       k8sfip.write(args.floatingip1)

    k8stemplate = (template.render(
        username=args.username,
        projectname=args.projectname,
        clustername=args.clustername,
        nodes=args.nodes,
        subnetcidr=args.subnetcidr,
        calicocidr=args.calicocidr,
        keypair=args.keypair,
        imageflavor=args.imageflavor,
        floatingip1=args.floatingip1,
        floatingip2=args.floatingip2,
        ))

    k8sconfig_template = (config_template.render(
        dnsserver=args.dnsserver,
        floatingip1=args.floatingip1,
        k8sver=args.k8sver,
        flannelver=args.flannelver,
        sshkey1=args.sshkey1,
        sshkey2=args.sshkey2,
        cloudprovider=args.cloudprovider,
        corepassword=args.corepassword,
        subnetcidr=args.subnetcidr,
        calicocidr=args.calicocidr,
        masterhostip=(args.subnetcidr).rsplit('.', 1)[0]+".10",
        masterhostgw=(args.subnetcidr).rsplit('.', 1)[0]+".1",
        workergw=(args.subnetcidr).rsplit('.', 1)[0]+".1",
        workerip1=(args.subnetcidr).rsplit('.', 1)[0]+".11",
        workerip2=(args.subnetcidr).rsplit('.', 1)[0]+".12",
        ))

    kubeconfig_template = (kubeconfig_template.render(
        floatingip1=args.floatingip1,
        masterhostip=(args.subnetcidr).rsplit('.', 1)[0]+".10"
        ))

    cloudconfig_template = (cloudconfig_template.render(
        authurl=os.environ["OS_AUTH_URL"],
        username=args.username,
        password=os.environ["OS_PASSWORD"],
        region=os.environ["OS_REGION_NAME"],
        projectname=args.projectname,
        tenantid=os.environ["OS_TENANT_ID"],
        ))

    with open('kubeconfig.sh', 'w') as kubeconfig:
        kubeconfig.write(kubeconfig_template)

    with open('config.env', 'w') as k8sconfig:
        k8sconfig.write(k8sconfig_template)

    with open('k8s.tf', 'w') as k8s:
       k8s.write(k8stemplate)

    with open('cloud.conf', 'w') as cloudconf:
       cloudconf.write(cloudconfig_template)

    list=""
    listArray=[]
    for node in range(10,args.nodes+10):
       lanip = str(args.subnetcidr.rsplit('.', 1)[0] + "." + str(node) + " ")
       list = list + lanip
       listArray.append(lanip)

    with open('k8s_cluster_ips.txt', 'w') as k8scips:
       k8scips.write(str(list))


    subprocess.call(["git", "clone", "-b", args.gitbranch, "https://github.com/pblaas/cloudinit_generator.git"])
    subprocess.call(["cp", "-v", "config.env", "./cloudinit_generator"])
    subprocess.check_call('echo YES | ./create_cloudinit.sh', shell=True, cwd='./cloudinit_generator')

    if len(listArray) > 3:
        for i in range(3, len(listArray)):
            ip = listArray[i]
            subprocess.check_call(['./add_node.sh', ip], cwd='./cloudinit_generator')

except Exception as e:
    raise
else:
    print("-----------------------------")
    print("Config generation succesfull.")
    print("Bootstrapping the cluster can take 3-5 minutes. Please be patient.\n")
    print("To start building the cluster: \nterraform init && terraform plan && terraform apply && sh snat_acl.sh")
    print("To interact with the cluster: \nsh kubeconfig.sh")
