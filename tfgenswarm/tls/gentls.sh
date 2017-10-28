#!/bin/bash
#temporary shell TLS script until inplemented in python.
#create root CA
if [ $1 ]; then
openssl genrsa -out ca-key.pem 2048
openssl req -x509 -new -nodes -key ca-key.pem -days 10000 -out ca.pem -subj "/CN=swarwm-ca"
sed -e s/FLOATING_IP/$1/ openssl.tmpl.cnf > openssl.cnf
# server cert
openssl genrsa -out swarmserver-key.pem 2048
openssl req -new -key swarmserver-key.pem -out swarmserver.csr -subj "/CN=swarmserver" -config openssl.cnf
openssl x509 -req -in swarmserver.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out swarmserver.pem -days 365 -extensions v3_req -extfile openssl.cnf

#client cert
openssl genrsa -out client1-key.pem 2048
openssl req -new -key client1-key.pem -out client1.csr -subj "/CN=client1" -config openssl.cnf
openssl x509 -req -in client1.csr -CA ca.pem -CAkey ca-key.pem -CAcreateserial -out client1.pem -days 365 -extensions v3_req -extfile openssl.cnf

echo Creating new alias swarm
alias swarm="docker --tlsverify --tlscacert=ca.pem --tlscert=client1.pem --tlskey=client1-key.pem -H=$1:2376"

#server needs dockerd --tlsverify --tlscacert=ca.pem --tlscert=swarmserver.pem --tlskey=swarmserver-key.pem -H=0.0.0.0:2376
#--tlsverify --tlscacert=ca.pem --tlscert=server-cert.pem --tlskey=server-key.pem \
#  -H=0.0.0.0:2376
# mkdir -p /etc/systemd/system/docker.service.d
#
#docker --tlsverify --tlscacert=ca.pem --tlscert=client1.pem --tlskey=client1-key.pem -H=$1:2376 version
#
#
# mkdir -pv ~/.docker
# cp -v {ca,cert,key}.pem ~/.docker
# export DOCKER_HOST=tcp://$HOST:2376 DOCKER_TLS_VERIFY=1

else 
	echo Syntax error
	echo You need to provide a server ip for which you like the TLS certs to be generated.
	echo ./$0 YOURFLOATINGIPHERE

fi
