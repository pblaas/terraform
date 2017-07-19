#!/bin/bash
apt-get update -y
apt-get install docker.io docker-compose -y
systemctl start docker
docker pull pblaas/hitch
docker pull pblaas/varnish4
docker-compose up -d
