#!/usr/bin/env python
__author__ = "Patrick Blaas <patrick@kite4fun.nl>"
__license__ = "MIT"
__version__ = "0.1.4"
__status__ = "Prototype"

import argparse
import os
import subprocess
import base64
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
parser.add_argument("--username", help="Openstack username - (OS_USERNAME environment variable)", default=os.environ["OS_USERNAME"])
parser.add_argument("--projectname", help="Openstack project Name - (OS_TENANT_NAME environment variable)", default=os.environ["OS_TENANT_NAME"])
parser.add_argument("--clustername", help="Clustername - (swarmcluster)", default="swarmcluster")
parser.add_argument("--subnetcidr", help="Private subnet CIDR - (192.168.3.0/24)", default="192.168.3.0/24")
parser.add_argument("--calicocidr", help="Calico subnet CIDR - (10.244.0.0/16)", default="10.244.0.0/16")
parser.add_argument("--managernodes", help="Number of swarm manager nodes - (3)", type=int, default=3)
parser.add_argument("--workernodes", help="Number of swarm workers nodes - (2)", type=int, default=2)
parser.add_argument("--imageflavor", help="Image flavor ID - (2008)", type=int, default=2008)
parser.add_argument("--cloudprovider", help="Cloud provider support - (openstack)", default="openstack")
parser.add_argument("--flannelver", help="Flannel image version - (v0.8.0)", default="v0.8.0")
args = parser.parse_args()

template = TEMPLATE_ENVIRONMENT.get_template('swarm.tf.tmpl')
bootstrap_template = TEMPLATE_ENVIRONMENT.get_template('swarmbootstrap.sh.tmpl')
openssl_template = TEMPLATE_ENVIRONMENT.get_template('./tls/openssl.cnf.tmpl')
worker_template = TEMPLATE_ENVIRONMENT.get_template('swarmworker.sh.tmpl')
manager_template = TEMPLATE_ENVIRONMENT.get_template('swarmmanager.sh.tmpl')
cloudconfig_template = TEMPLATE_ENVIRONMENT.get_template('cloud.conf.tmpl')

try:
    if args.managernodes < 3:
        raise Exception('Nodes need to be no less then 3.')

    openssltemplate = (openssl_template.render(
        floatingip1=args.floatingip1
        ))

    with open('./tls/openssl.cnf', 'w') as openssl:
       openssl.write(openssltemplate)

    #subprocess.check_call('echo YES | ./create_cloudinit.sh', shell=True, cwd='./cloudinit_generator')
    subprocess.call(["openssl", "genrsa", "-out", "ca-key.pem", "2048"], cwd='./tls')
    subprocess.call(["openssl", "req", "-x509", "-new", "-nodes", "-key", "ca-key.pem", "-days", "10000", "-out", "ca.pem", "-subj", "/CN=swarm-ca"], cwd='./tls')
    subprocess.call(["openssl", "genrsa", "-out", "swarmserver-key.pem", "2048"], cwd='./tls')
    subprocess.call(["openssl", "req", "-new", "-key", "swarmserver-key.pem", "-out", "swarmserver.csr", "-subj", "/CN=swarmserver", "-config", "openssl.cnf"], cwd='./tls')
    subprocess.call(["openssl", "x509", "-req", "-in", "swarmserver.csr", "-CA", "ca.pem", "-CAkey", "ca-key.pem", "-CAcreateserial", "-out", "swarmserver.pem", "-days", "365", "-extensions", "v3_req", "-extfile", "openssl.cnf"], cwd='./tls')

    subprocess.call(["openssl", "genrsa", "-out", "client1-key.pem", "2048"], cwd='./tls')
    subprocess.call(["openssl", "req", "-new", "-key", "client1-key.pem", "-out", "client1.csr", "-subj", "/CN=client1", "-config", "openssl.cnf"], cwd='./tls')
    subprocess.call(["openssl", "x509", "-req", "-in", "client1.csr", "-CA", "ca.pem", "-CAkey", "ca-key.pem", "-CAcreateserial", "-out", "client1.pem", "-days", "365", "-extensions", "v3_req", "-extfile", "openssl.cnf"], cwd='./tls')


    swarmtemplate = (template.render(
        username=args.username,
        projectname=args.projectname,
        clustername=args.clustername,
        managernodes=args.managernodes,
        workernodes=args.workernodes,
        subnetcidr=args.subnetcidr,
        calicocidr=args.calicocidr,
        keypair=args.keypair,
        imageflavor=args.imageflavor,
        floatingip1=args.floatingip1,
        floatingip2=args.floatingip2,
        ))


    buffer = open('./tls/ca.pem', 'rU').read()
    CAPEM=base64.b64encode(buffer)
    buffer = open('./tls/swarmserver.pem', 'rU').read()
    SWARMCERT=base64.b64encode(buffer)
    buffer = open('./tls/swarmserver-key.pem', 'rU').read()
    SWARMKEY=base64.b64encode(buffer)

    bootstrap_template = (bootstrap_template.render(
        CAPEM=CAPEM,
        SWARMCERT=SWARMCERT,
        SWARMKEY=SWARMKEY
        ))

    worker_template = (worker_template.render(
        bootstrapmaster=(args.subnetcidr).rsplit('.', 1)[0]+".10",
        ))

    manager_template = (manager_template.render(
        bootstrapmaster=(args.subnetcidr).rsplit('.', 1)[0]+".10",
        ))

    cloudconfig_template = (cloudconfig_template.render(
        authurl=os.environ["OS_AUTH_URL"],
        username=args.username,
        password=os.environ["OS_PASSWORD"],
        region=os.environ["OS_REGION_NAME"],
        projectname=args.projectname,
        tenantid=os.environ["OS_TENANT_ID"],
        ))


    with open('swarm.tf', 'w') as swarm:
       swarm.write(swarmtemplate)

    with open('swarmbootstrap.sh', 'w') as swarmbootstrap:
       swarmbootstrap.write(bootstrap_template)

    with open('swarmworker.sh', 'w') as swarmworker:
       swarmworker.write(worker_template)

    with open('swarmmanager.sh', 'w') as swarmmanager:
       swarmmanager.write(manager_template)

    with open('cloud.conf', 'w') as cloudconf:
       cloudconf.write(cloudconfig_template)

    with open('swarmalias.sh', 'w') as swarmaliassh:
       swarmaliassh.write("alias swarm=\"docker --tlsverify --tlscacert="+PATH+"/tls/ca.pem --tlscert="+PATH+"/tls/client1.pem --tlskey="+PATH+"/tls/client1-key.pem -H="+args.floatingip1+":2376\"")


except Exception as e:
    raise
else:
    print("-----------------------------")
    print("Config generation succesfull.")
    print("You can add the following alias to control the new cluster:")
    print("alias swarm=\"docker --tlsverify --tlscacert="+PATH+"/tls/ca.pem --tlscert="+PATH+"/tls/client1.pem --tlskey="+PATH+"/tls/client1-key.pem -H="+args.floatingip1+":2376\"")
    print("")
    print("Bootstrapping the cluster can take 2-5 minutes. Please be patient.\n")
    print("To start building the cluster: \nterraform init && terraform plan && terraform apply")
    print("")
