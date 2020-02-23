# Setup Instructions

1. Create Nginx Disk Image

```sh
cd web_image
terraform init
terraform apply
```

Create image "web-image" once disk is up and running.

2. Provision test environment

```sh
terraform init
terraform apply
```

# Miscellaneous

## Add routing to the VMs

Add routing to ensure healthcheck via nic1 is routed out to nic1
```sh
echo "100 rt-nic1" >> /etc/iproute2/rt_tables
ip rule add pri 32000 from 192.168.1.1/255.255.255.0 table rt-nic1
sleep 1
ip route add 35.191.0.0/16 via 192.168.1.1 dev eth1 table rt-nic1
ip route add 130.211.0.0/22 via 192.168.1.1 dev eth1 table rt-nic1
```
Reference: https://cloud.google.com/load-balancing/docs/internal/setting-up-ilb-next-hop#ilb-nh-single-nic-setup

