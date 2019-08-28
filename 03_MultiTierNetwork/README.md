# Setup SSH

https://cloud.google.com/compute/docs/instances/connecting-advanced#sshbetweeninstances

```sh
ssh-add ~/.ssh/[PRIVATE_KEY]

# Add `-A` argument to enable authentication agent forwarding

ssh -A [USERNAME]@[BASTION_HOST_EXTERNAL_IP_ADDRESS]

ssh [USERNAME]@[INTERNAL_INSTANCE_IP_ADDRESS]
```

# Environment variables
export GOOGLE_APPLICATION_CREDENTIALS=${JSON_FILE}
export TF_VAR_public_key=${KEY_PATH}

# Configurations

## Squid3

```sh
# /etc/squid.conf
acl AllowHost src "/etc/squid/AllowHost.txt"
http_access allow AllowHost
```

## Apt Proxy

```sh
# cat /etc/apt/apt.conf
Acquire::http::Proxy "http://172.16.3.3:3128";
```

## Add Route

```
ip route add {NETWORK/MASK} via {GATEWAYIP}
ip route add {NETWORK/MASK} dev {DEVICE}
ip route add default {NETWORK/MASK} dev {DEVICE}
ip route add default {NETWORK/MASK} via {GATEWAYIP}
```

example
```
sudo ifconfig eth1 172.16.3.3 netmask 255.255.255.255 broadcast 172.16.3.3 mtu 1430
echo "1 rt1" | sudo tee -a /etc/iproute2/rt_tables
sudo ip route add 172.16.3.1 src 172.16.3.3 dev eth1 table rt1
sudo ip route add default via 172.16.3.1 dev eth1 table rt1
sudo ip rule add from 172.16.3.3/24 table rt1
sudo ip rule add to 172.16.3.3/24 table rt1
```
