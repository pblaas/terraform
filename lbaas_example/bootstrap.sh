#!/bin/bash
apt-get update
apt-get install -y nginx
rm -vf /var/www/html/*
echo $(hostname) > /var/www/html/index.html
