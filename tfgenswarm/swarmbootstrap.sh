#!/bin/bash
# Master Bootstrap
apt-get update
apt-get install -y \
  apt-transport-https \
  ca-certificates \
  curl \
  software-properties-common \
  jq \
  etcd

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu  $(lsb_release -cs) stable"
apt-get update
apt-get install -y docker-ce

echo '
ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://0.0.0.0:2380,http://0.0.0.0:7001"
ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379,http://0.0.0.0:4001"
' >> /etc/default/etcd

## need to write workerinfo and master info to etcd cluster.
service etcd restart

#initialize docker swarm.
docker swarm init

#write worker and manager tokens to etcd.
etcdctl set worker-token $(docker swarm join-token worker|grep token|awk '{ print $5 }')
etcdctl set manager-token $(docker swarm join-token manager|grep token|awk '{ print $5 }')

echo 'ICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIGIKICAgICAgICAgICAgICAgICAgICAgICAgICAgIC4gICQgIC4KICAgICAgICAuLi4uICAgICAgICAgICAgIGQgICogICogICQgICAgLgogICAuemUkJCQkJCQkJGJlLi4gICAgICAgXmIgXkwgNEYgJCAgICAkCiAgZSQkJCQkJCQkJCQkJCQkJCRlICAgICAgIkwgJCAgYiAkICAgSiUKLiQkJCQkJCQkJCQkJCRQKioiIioqICAgICAgM3InTCAkICQgIDRGCiAiKiQkJCQkJCQkKiIgICAgICAgICAgICAgICAqLiQgMyAkICAkCiAgICokJCQkJCIgICAgICAgICAgICAgICAgICBeJCdyJyRQIGQiCiAgIF4kJCQiICAgICAgICAgICAgICAgICAgICAgXiQkICRGNEYKICAgICQkJCAgICAgICAgICAgICAgICAgICAgICAgIiRyKmJQCiAgICAkJCRGICAgICAgICAgICAgICAgICAgICAgICAgIjQkIgogICAgJCQkJCAgICAgICAgICAgICAgICAgICAgICAgICBeIgogICAgJCQkJGIgICAgICAgICAgICAgIC4uZWVlZWQkJCQkJCQkJGVlZWUuLi4KICAgICokJCQkYi4gICAgICAgLnplJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJGJlLi4KICAgICckJCQkJCRiZWUuLmUkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCRiYwogICAgIDMkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJGMKICAgICAgIiokJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkcgogICAgICAgIF4iIiIiJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkZS4uICAgICAgICBQCiAgICAgICAgICAgICAiJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJCQkJGJlZS56QCIKICAgICAgICAgICAgICBeKiQkJCQkJCQkKiIiIiAgICAgIiIiIioqJCQkJCQkJCQkJCQkJCIKICAgICAgICAgICAgICAgIF4iKiQkJCIgICAgICAgICAgICAgICAgICIiKiQkJCQkJCoiCiAgICAgICAgICAgICAgICAgICAgIiIqKmVlZWMuLi4uLi4uLi4uLi5lZWVAKioiIiAgIEdpbG85NCcKICAgICAgICAgICAgICAgICAgICAgICAgICAgIiIiIiIiIiIiIiIiIiIK' |base64 -di > /etc/motd
echo 'IyNyb290QHN3YXJtLXN3YXJtY2x1c3Rlci1ub2RlMTA6L2V0Yy9zeXN0ZW1kL3N5c3RlbSMgY2F0IGRvY2tlci10bHMuc2VydmljZSAKW1VuaXRdCkRlc2NyaXB0aW9uPURvY2tlciBBcHBsaWNhdGlvbiBDb250YWluZXIgRW5naW5lCkRvY3VtZW50YXRpb249aHR0cHM6Ly9kb2NzLmRvY2tlci5jb20KQWZ0ZXI9bmV0d29yay1vbmxpbmUudGFyZ2V0IGRvY2tlci5zb2NrZXQgZmlyZXdhbGxkLnNlcnZpY2UKV2FudHM9bmV0d29yay1vbmxpbmUudGFyZ2V0CgpbU2VydmljZV0KVHlwZT1ub3RpZnkKIyB0aGUgZGVmYXVsdCBpcyBub3QgdG8gdXNlIHN5c3RlbWQgZm9yIGNncm91cHMgYmVjYXVzZSB0aGUgZGVsZWdhdGUgaXNzdWVzIHN0aWxsCiMgZXhpc3RzIGFuZCBzeXN0ZW1kIGN1cnJlbnRseSBkb2VzIG5vdCBzdXBwb3J0IHRoZSBjZ3JvdXAgZmVhdHVyZSBzZXQgcmVxdWlyZWQKIyBmb3IgY29udGFpbmVycyBydW4gYnkgZG9ja2VyCkV4ZWNTdGFydD0vdXNyL2Jpbi9kb2NrZXJkIC0tdGxzdmVyaWZ5IC0tdGxzY2FjZXJ0PS9ldGMvc3NsL2NlcnRzL2NhLnBlbSAtLXRsc2NlcnQ9L2V0Yy9zc2wvY2VydHMvc3dhcm1zZXJ2ZXIucGVtIC0tdGxza2V5PS9ldGMvc3NsL3ByaXZhdGUvc3dhcm1zZXJ2ZXIta2V5LnBlbSAtSD0wLjAuMC4wOjIzNzYgCkV4ZWNSZWxvYWQ9L2Jpbi9raWxsIC1zIEhVUCAkTUFJTlBJRApMaW1pdE5PRklMRT0xMDQ4NTc2CiMgSGF2aW5nIG5vbi16ZXJvIExpbWl0KnMgY2F1c2VzIHBlcmZvcm1hbmNlIHByb2JsZW1zIGR1ZSB0byBhY2NvdW50aW5nIG92ZXJoZWFkCiMgaW4gdGhlIGtlcm5lbC4gV2UgcmVjb21tZW5kIHVzaW5nIGNncm91cHMgdG8gZG8gY29udGFpbmVyLWxvY2FsIGFjY291bnRpbmcuCkxpbWl0TlBST0M9aW5maW5pdHkKTGltaXRDT1JFPWluZmluaXR5CiMgVW5jb21tZW50IFRhc2tzTWF4IGlmIHlvdXIgc3lzdGVtZCB2ZXJzaW9uIHN1cHBvcnRzIGl0LgojIE9ubHkgc3lzdGVtZCAyMjYgYW5kIGFib3ZlIHN1cHBvcnQgdGhpcyB2ZXJzaW9uLgpUYXNrc01heD1pbmZpbml0eQpUaW1lb3V0U3RhcnRTZWM9MAojIHNldCBkZWxlZ2F0ZSB5ZXMgc28gdGhhdCBzeXN0ZW1kIGRvZXMgbm90IHJlc2V0IHRoZSBjZ3JvdXBzIG9mIGRvY2tlciBjb250YWluZXJzCkRlbGVnYXRlPXllcwojIGtpbGwgb25seSB0aGUgZG9ja2VyIHByb2Nlc3MsIG5vdCBhbGwgcHJvY2Vzc2VzIGluIHRoZSBjZ3JvdXAKS2lsbE1vZGU9cHJvY2VzcwojIHJlc3RhcnQgdGhlIGRvY2tlciBwcm9jZXNzIGlmIGl0IGV4aXRzIHByZW1hdHVyZWx5ClJlc3RhcnQ9b24tZmFpbHVyZQpTdGFydExpbWl0QnVyc3Q9MwpTdGFydExpbWl0SW50ZXJ2YWw9NjBzCgpbSW5zdGFsbF0KV2FudGVkQnk9bXVsdGktdXNlci50YXJnZXQKCg==' | base64 -di > /etc/systemd/system/docker-tls.service
systemctl daemon-reload
systemctl stop docker && systemctl disable docker
systemctl start docker-tls

