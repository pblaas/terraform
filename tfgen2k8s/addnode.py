#!/usr/bin/env python2.7
"""Kubernetes cluster generator - addnode."""
__author__ = "Patrick Blaas <patrick@kite4fun.nl>"
__license__ = "MIT"
__version__ = "0.0.1"
__status__ = "Prototype"


import argparse
import httplib
import os
import subprocess
import base64
from jinja2 import Environment, FileSystemLoader

PATH = os.path.dirname(os.path.abspath(__file__))
TEMPLATE_ENVIRONMENT = Environment(
    autoescape=False,
    loader=FileSystemLoader(os.path.join(PATH, '.')),
    trim_blocks=True)


# Testing if environment variables are available.
if not "OS_USERNAME" in os.environ:
    os.environ["OS_USERNAME"] = "Default"
if not "OS_PASSWORD" in os.environ:
    os.environ["OS_PASSWORD"] = "Default"
if not "OS_TENANT_NAME" in os.environ:
    os.environ["OS_TENANT_NAME"] = "Default"
if not "OS_TENANT_ID" in os.environ:
    os.environ["OS_TENANT_ID"] = "Default"
if not "OS_REGION_NAME" in os.environ:
    os.environ["OS_REGION_NAME"] = "Default"
if not "OS_AUTH_URL" in os.environ:
    os.environ["OS_AUTH_URL"] = "Default"

parser = argparse.ArgumentParser()
parser.add_argument("ipaddress", help="node ip address")
parser.add_argument("--workerimageflavor", help="Worker image flavor ID - (2008)", type=int, default=2008)
parser.add_argument("--username", help="Openstack username - (OS_USERNAME environment variable)", default=os.environ["OS_USERNAME"])
parser.add_argument("--projectname", help="Openstack project Name - (OS_TENANT_NAME environment variable)", default=os.environ["OS_TENANT_NAME"])
args = parser.parse_args()

template = TEMPLATE_ENVIRONMENT.get_template('k8s.tf.tmpl')
config_template = TEMPLATE_ENVIRONMENT.get_template('config.env.tmpl')
calico_template = TEMPLATE_ENVIRONMENT.get_template('calico.yaml.tmpl')
cloudconf_template = TEMPLATE_ENVIRONMENT.get_template('k8scloudconf.yaml.tmpl')
kubeconfig_template = TEMPLATE_ENVIRONMENT.get_template('kubeconfig.sh.tmpl')
cloudconfig_template = TEMPLATE_ENVIRONMENT.get_template('cloud.conf.tmpl')
opensslmanager_template = TEMPLATE_ENVIRONMENT.get_template('./tls/openssl.cnf.tmpl')
opensslworker_template = TEMPLATE_ENVIRONMENT.get_template('./tls/openssl-worker.cnf.tmpl')


try:
    #Create node certificates
    def createNodeCert(nodeip, k8srole):
        """Create Node certificates."""
        print("received: " + nodeip)
        if k8srole == "manager":
            openssltemplate = (opensslmanager_template.render(
                floatingip1=args.floatingip1,
                ipaddress=nodeip,
                loadbalancer=(args.subnetcidr).rsplit('.', 1)[0]+".3"
                ))
        else:
            openssltemplate = (opensslworker_template.render(
                ipaddress=nodeip,
                ))

        with open('./tls/openssl.cnf', 'w') as openssl:
            openssl.write(openssltemplate)

        nodeoctet = nodeip.rsplit('.')[3]
        subprocess.call(["openssl", "genrsa", "-out", nodeip +"-k8s-node-key.pem", "2048"], cwd='./tls')
        subprocess.call(["openssl", "req", "-new", "-key", nodeip +"-k8s-node-key.pem", "-out", nodeip +"-k8s-node.csr", "-subj", "/CN=system:node:k8s-"+str(args.clustername)+"-node"+str(nodeoctet)+"/O=system:nodes", "-config", "openssl.cnf"], cwd='./tls')
        subprocess.call(["openssl", "x509", "-req", "-in", nodeip +"-k8s-node.csr", "-CA", "ca.pem", "-CAkey", "ca-key.pem", "-CAcreateserial", "-out", nodeip+"-k8s-node.pem", "-days", "365", "-extensions", "v3_req", "-extfile", "openssl.cnf"], cwd='./tls')

        # ${i}-etcd-worker.pem
        subprocess.call(["openssl", "genrsa", "-out", nodeip +"-etcd-node-key.pem", "2048"], cwd='./tls')
        subprocess.call(["openssl", "req", "-new", "-key", nodeip +"-etcd-node-key.pem", "-out", nodeip +"-etcd-node.csr", "-subj", "/CN="+nodeip+"-etcd-node", "-config", "openssl.cnf"], cwd='./tls')
        subprocess.call(["openssl", "x509", "-req", "-in", nodeip +"-etcd-node.csr", "-CA", "etcd-ca.pem", "-CAkey", "etcd-ca-key.pem", "-CAcreateserial", "-out", nodeip+"-etcd-node.pem", "-days", "365", "-extensions", "v3_req", "-extfile", "openssl.cnf"], cwd='./tls')



    def printClusterInfo():
        """Print cluster info."""
        print("-"*40+"\n\nCluster Info:")
        print("Etcd ID token:\t" + str(etcdTokenId.rsplit('/', 1)[1]))
        print("k8s version:\t" + str(args.k8sver))
        print("Clustername:\t" + str(args.clustername))
        print("Cluster cidr:\t" + str(args.subnetcidr))
        print("Managers:\t" + str(args.managers))
        print("Workers:\t" + str(args.workers))
        print("Manager img:\t" +str(args.managerimageflavor))
        print("Worker img:\t" +str(args.workerimageflavor))
        print("VIP1:\t\t" + str(args.floatingip1))
        print("VIP2:\t\t" + str(args.floatingip2))
        print("Dnsserver:\t" +str(args.dnsserver))
        print("Net overlay:\t" + str(args.netoverlay))
        print("Auth mode:\t" + str(args.authmode))
        print("-"*40+"\n")
        print("To start building the cluster: \tterraform init && terraform plan && terraform apply && sh snat_acl.sh")
        print("To interact with the cluster: \tsh kubeconfig.sh")


    buffer = open('./tls/ca.pem', 'rU').read()
    CAPEM = base64.b64encode(buffer)

    buffer = open('./tls/etcd-ca.pem', 'rU').read()
    ETCDCAPEM = base64.b64encode(buffer)

    cloudconfig_template = (cloudconfig_template.render(
        authurl=os.environ["OS_AUTH_URL"],
        username=args.username,
        password=os.environ["OS_PASSWORD"],
        region=os.environ["OS_REGION_NAME"],
        projectname=args.projectname,
        tenantid=os.environ["OS_TENANT_ID"],
        ))

    with open('cloud.conf', 'w') as cloudconf:
        cloudconf.write(cloudconfig_template)


    buffer = open('cloud.conf', 'rU').read()
    cloudconfbase64 = base64.b64encode(buffer)

    iplist = ""
    for node in range(10, args.managers+10):
        apiserver = str("https://" + args.subnetcidr.rsplit('.', 1)[0] + "." + str(node) + ":2379,")
        iplist = iplist + apiserver

    print("Apiservers: "+ iplist.rstrip(','))


    if args.ipaddress != "": 
        lanip = str(args.ipaddress)
        nodeyaml = str("node_" + lanip.rstrip(' ') + ".yaml")
        createNodeCert(lanip, "worker")
        buffer = open("./tls/"+ str(lanip)+ "-k8s-node.pem", 'rU').read()
        k8snodebase64 = base64.b64encode(buffer)
        buffer = open('./tls/'+str(lanip)+"-k8s-node-key.pem", 'rU').read()
        k8snodekeybase64 = base64.b64encode(buffer)
        buffer = open('./tls/'+str(lanip)+"-etcd-node.pem", 'rU').read()
        etcdnodebase64 = base64.b64encode(buffer)
        buffer = open('./tls/'+str(lanip)+"-etcd-node-key.pem", 'rU').read()
        etcdnodekeybase64 = base64.b64encode(buffer)

        worker_template = (cloudconf_template.render(
            isworker=1,
            workers=args.workers,
            dnsserver=args.dnsserver,
            etcdendpointsurls=iplist.rstrip(','),
            floatingip1=args.floatingip1,
            k8sver=args.k8sver,
            flannelver=args.flannelver,
            netoverlay=args.netoverlay,
            cloudprovider=args.cloudprovider,
            authmode=args.authmode,
            clustername=args.clustername,
            subnetcidr=args.subnetcidr,
            calicocidr=args.calicocidr,
            ipaddress=lanip,
            ipaddressgw=(args.subnetcidr).rsplit('.', 1)[0]+".1",
            loadbalancer=(args.subnetcidr).rsplit('.', 1)[0]+".3",
            discoveryid=discovery_id,
            cabase64=CAPEM,
            etcdcabase64=ETCDCAPEM,
            k8snodebase64=k8snodebase64,
            k8snodekeybase64=k8snodekeybase64,
            etcdnodebase64=etcdnodebase64,
            etcdnodekeybase64=etcdnodekeybase64,
            cloudconfbase64=cloudconfbase64,
            ))

        with open(nodeyaml, 'w') as worker:
            worker.write(worker_template)

    with open('k8s.tf', 'w') as k8s:
        k8s.write(k8stemplate)

except Exception as e:
    raise
else:
    printClusterInfo()
