#!/bin/bash
docker plugin install --grant-all-permissions rexray/cinder:latest \
  CINDER_AUTHURL=Default \
  CINDER_USERNAME=Default \
  CINDER_PASSWORD=Default \
  CINDER_TENANTID=Default \
  CINDER_TENANTNAME="Default" \
  CINDER_DOMAINNAME=Default \
  CINDER_REGIONNAME=Default \
  CINDER_AVAILABILITYZONENAME=AMS-EQ1 \
  REXRAY_PREEMPT=true \
  REXRAY_LOGLEVEL=debug
