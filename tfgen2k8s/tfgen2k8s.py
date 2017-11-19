#!/usr/bin/env python
__author__ = "Patrick Blaas <patrick@kite4fun.nl>"
__license__ = "MIT"
__version__ = "0.0.1"
__status__ = "Prototype"

import argparse
import os
import subprocess
import httplib
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
parser.add_argument("--corepassword", help="Password to authenticate with core user")
parser.add_argument("--username", help="Openstack username - (OS_USERNAME environment variable)", default=os.environ["OS_USERNAME"])
parser.add_argument("--projectname", help="Openstack project Name - (OS_TENANT_NAME environment variable)", default=os.environ["OS_TENANT_NAME"])
parser.add_argument("--clustername", help="Clustername - (k8scluster)", default="k8scluster")
parser.add_argument("--subnetcidr", help="Private subnet CIDR - (192.168.3.0/24)", default="192.168.3.0/24")
parser.add_argument("--calicocidr", help="Calico subnet CIDR - (10.244.0.0/16)", default="10.244.0.0/16")
parser.add_argument("--managers", help="Number of k8s managers - (3)", type=int, default=3)
parser.add_argument("--workers", help="Number of k8s workers - (2)", type=int, default=2)
parser.add_argument("--managerimageflavor", help="Manager image flavor ID - (2007)", type=int, default=2007)
parser.add_argument("--workerimageflavor", help="Worker image flavor ID - (2008)", type=int, default=2008)
parser.add_argument("--dnsserver", help="DNS server - (8.8.8.8)", default="8.8.8.8")
parser.add_argument("--cloudprovider", help="Cloud provider support - (openstack)", default="openstack")
parser.add_argument("--k8sver", help="Hyperkube version - (v1.7.9_coreos.0)", default="v1.7.9_coreos.0")
parser.add_argument("--flannelver", help="Flannel image version - (v0.8.0)", default="v0.8.0")
parser.add_argument("--netoverlay", help="Network overlay - (flannel)", default="flannel")
parser.add_argument("--authmode", help="Authorization mode - (AlwaysAllow)", default="AlwaysAllow")
parser.add_argument("--gitbranch", help="Cloudinit_generator branch - (master)", default="master")
args = parser.parse_args()

template = TEMPLATE_ENVIRONMENT.get_template('k8s.tf.tmpl')
config_template = TEMPLATE_ENVIRONMENT.get_template('config.env.tmpl')
controller_template = TEMPLATE_ENVIRONMENT.get_template('controller.yaml.tmpl')
kubeconfig_template = TEMPLATE_ENVIRONMENT.get_template('kubeconfig.sh.tmpl')
cloudconfig_template = TEMPLATE_ENVIRONMENT.get_template('cloud.conf.tmpl')
openssl_template = TEMPLATE_ENVIRONMENT.get_template('./tls/openssl.cnf.tmpl')

try:
    #Create CA certificates
    def createCaCert():
            print("CA")
            subprocess.call(["openssl", "genrsa", "-out", "ca-key.pem", "2048"], cwd='./tls')
            subprocess.call(["openssl", "req", "-x509", "-new", "-nodes", "-key", "ca-key.pem", "-days", "10000", "-out", "ca.pem", "-subj", "/CN=k8s-ca"], cwd='./tls')

            print("etcd CA")
            subprocess.call(["openssl", "genrsa", "-out", "etcd-ca-key.pem", "2048"], cwd='./tls')
            subprocess.call(["openssl", "req", "-x509", "-new", "-nodes", "-key", "etcd-ca-key.pem", "-days", "10000", "-out", "etcd-ca.pem", "-subj", "/CN=etcd-k8s-ca"], cwd='./tls')

    #Create node certificates
    def createNodeCert(node):
            print("received: " + node)
            nodeoctet=node.rsplit('.')[3]
            subprocess.call(["openssl", "genrsa", "-out", node +"-k8s-node-key.pem", "2048"], cwd='./tls')
            subprocess.call(["openssl", "req", "-new", "-key", node +"-k8s-node-key.pem", "-out", node +"-k8s-node.csr", "-subj", "/CN=system:node:k8s-"+str(args.clustername)+"-node"+str(nodeoctet)+"/O=system:nodes", "-config", "openssl.cnf"], cwd='./tls')
            subprocess.call(["openssl", "x509", "-req", "-in", node +"-k8s-node.csr", "-CA", "ca.pem", "-CAkey", "ca-key.pem", "-CAcreateserial", "-out", node+"-k8s-node.pem", "-days", "365", "-extensions", "v3_req", "-extfile", "openssl.cnf"], cwd='./tls')

            # ${i}-etcd-worker.pem
            subprocess.call(["openssl", "genrsa", "-out", node +"-etcd-node-key.pem", "2048"], cwd='./tls')
            subprocess.call(["openssl", "req", "-new", "-key", node +"-etcd-node-key.pem", "-out", node +"-etcd-node.csr", "-subj", "/CN="+node+"-etcd-node", "-config", "openssl.cnf"], cwd='./tls')
            subprocess.call(["openssl", "x509", "-req", "-in", node +"-etcd-node.csr", "-CA", "etcd-ca.pem", "-CAkey", "etcd-ca-key.pem", "-CAcreateserial", "-out", node+"-etcd-node.pem", "-days", "365", "-extensions", "v3_req", "-extfile", "openssl.cnf"], cwd='./tls')

    #Create client certificates
    def createClientCert(user):
            print("client: " + user)
            subprocess.call(["openssl", "genrsa", "-out", user +"-key.pem", "2048"], cwd='./tls')
            subprocess.call(["openssl", "req", "-new", "-key", user +"-key.pem", "-out", user+".csr", "-subj", "/CN="+user+"/O=system:masters", "-config", "openssl.cnf"], cwd='./tls')
            subprocess.call(["openssl", "x509", "-req", "-in", user+".csr", "-CA", "ca.pem", "-CAkey", "ca-key.pem", "-CAcreateserial", "-out", user+".pem", "-days", "365", "-extensions", "v3_req", "-extfile", "openssl.cnf"], cwd='./tls')

    def createClusterId():
            discoverurl = httplib.HTTPSConnection('discovery.etcd.io', timeout=10)
            discoversize="/new?size="+ str(args.managers)
            discoverurl.request("GET", discoversize)
            return discoverurl.getresponse().read()

    if args.managers < 3:
        raise Exception('Managers need to be no less then 3.')

    createClusterId()

    openssltemplate = (openssl_template.render(
        floatingip1=args.floatingip1,
        loadbalancer=(args.subnetcidr).rsplit('.', 1)[0]+".3"
        ))

    with open('./tls/openssl.cnf', 'w') as openssl:
       openssl.write(openssltemplate)

    createCaCert()

    with open('k8s_floating_ip.txt', 'w') as k8sfip:
        k8sfip.write(args.floatingip1)

    k8stemplate = (template.render(
        username=args.username,
        projectname=args.projectname,
        clustername=args.clustername,
        managers=args.managers,
        workers=args.workers,
        subnetcidr=args.subnetcidr,
        calicocidr=args.calicocidr,
        keypair=args.keypair,
        workerimageflavor=args.workerimageflavor,
        managerimageflavor=args.managerimageflavor,
        floatingip1=args.floatingip1,
        floatingip2=args.floatingip2,
        ))

    list=""
    for node in range(10,args.managers+10):
        apiserver = str("https://" + args.subnetcidr.rsplit('.', 1)[0] + "." + str(node) + ",")
        list = list + apiserver

    print("Apiservers: "+ list.rstrip(','))

    for node in range(10,args.managers+10):
        lanip = str(args.subnetcidr.rsplit('.', 1)[0] + "." + str(node))
        nodeyaml = str("node_" + lanip.rstrip(' ') + ".yaml")
        createNodeCert(lanip)
        master_template = (controller_template.render(
           dnsserver=args.dnsserver,
           etcdendpointsurls=list.rstrip(','),
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
           ))

        with open(nodeyaml, 'w') as controller:
          controller.write(master_template)

    '''
    k8sconfig_template = (config_template.render(
        dnsserver=args.dnsserver,
        floatingip1=args.floatingip1,
        k8sver=args.k8sver,
        flannelver=args.flannelver,
        netoverlay=args.netoverlay,
        sshkey1="none",
        sshkey2="none",
        cloudprovider=args.cloudprovider,
        authmode=args.authmode,
        clustername=args.clustername,
        corepassword="password",
        subnetcidr=args.subnetcidr,
        calicocidr=args.calicocidr,
        masterhostip=(args.subnetcidr).rsplit('.', 1)[0]+".10",
        masterhostgw=(args.subnetcidr).rsplit('.', 1)[0]+".1",
        workergw=(args.subnetcidr).rsplit('.', 1)[0]+".1",
        workerip1=(args.subnetcidr).rsplit('.', 1)[0]+".11",
        workerip2=(args.subnetcidr).rsplit('.', 1)[0]+".12",
        ))

    '''

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
    '''
    with open('config.env', 'w') as k8sconfig:
        k8sconfig.write(k8sconfig_template)
    '''

    with open('k8s.tf', 'w') as k8s:
       k8s.write(k8stemplate)

    with open('cloud.conf', 'w') as cloudconf:
       cloudconf.write(cloudconfig_template)

    list=""
    listArray=[]
    for node in range(10,args.managers+args.workers+10):
       lanip = str(args.subnetcidr.rsplit('.', 1)[0] + "." + str(node) + " ")
       list = list + lanip
       listArray.append(lanip)

    with open('k8s_cluster_ips.txt', 'w') as k8scips:
       k8scips.write(str(list))

    '''
    subprocess.call(["git", "clone", "-b", args.gitbranch, "https://github.com/pblaas/cloudinit_generator.git"])
    subprocess.call(["cp", "-v", "config.env", "./cloudinit_generator"])
    subprocess.check_call('echo YES | ./create_cloudinit.sh', shell=True, cwd='./cloudinit_generator')

    if len(listArray) > 3:
        for i in range(3, len(listArray)):
            ip = listArray[i]
            subprocess.check_call(['./add_node.sh', ip], cwd='./cloudinit_generator')
    '''

except Exception as e:
    raise
else:
    print("-----------------------------")
    print("Config generation succesfull.")
    print("Bootstrapping the cluster can take 3-5 minutes. Please be patient.\n")
    print("To start building the cluster: \nterraform init && terraform plan && terraform apply && sh snat_acl.sh")
    print("To interact with the cluster: \nsh kubeconfig.sh")
