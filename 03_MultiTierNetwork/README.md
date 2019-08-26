# Setup SSH

https://cloud.google.com/compute/docs/instances/connecting-advanced#sshbetweeninstances

```
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

```
# /etc/squid.conf
acl AllowHost src "/etc/squid/AllowHost.txt"
http_access allow AllowHost
```
