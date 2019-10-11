# Install ForgeRock OpenAM on GCE

## Enable OpenAM Stackdriver Logging

### OpenAM logger installation guideline
https://github.com/ForgeRock/ob-am-stackdriver-logger

#### ForgeRock maven repository settings.xml
https://backstage.forgerock.com/knowledge/kb/book/b40416457

### Install stackdriver agent on GCE
https://cloud.google.com/logging/docs/agent/installation

```sh
cd /tmp
curl -sSO https://dl.google.com/cloudagents/install-logging-agent.sh
chmod u+x install-logging-agent.sh
./install-logging-agent.sh 
```

Add OpenAM log files

Get the OpenAM log files `ls /root/openam/AM-6.5.2.1/log`
(Should match the location of the openam config directory)

Update fluentd
```sh
cd /etc/google-fluentd/config.d
cat <<EOF >openam.conf
<source>
    @type tail
    format none
    path /root/openam/AM-6.5.2.1/log/access.audit.json
    pos_file /var/lib/google-fluentd/pos/openam-access.audit.pos
    read_from_head true
    tag unstructured-log
</source>
<source>
    @type tail
    format none
    path /root/openam/AM-6.5.2.1/log/activity.audit.json
    pos_file /var/lib/google-fluentd/pos/openam-activity.audit.pos
    read_from_head true
    tag unstructured-log
</source>
<source>
    @type tail
    format none
    path /root/openam/AM-6.5.2.1/log/authentication.audit.json
    pos_file /var/lib/google-fluentd/pos/openam-authentication.audit.pos
    read_from_head true
    tag unstructured-log
</source>
<source>
    @type tail
    format none
    path /root/openam/AM-6.5.2.1/log/config.audit.json
    pos_file /var/lib/google-fluentd/pos/openam-config.audit.pos
    read_from_head true
    tag unstructured-log
</source>
# Restart fluentd
service google-fluentd restart
EOF
```

### Google Stackdriver Writer permission
Require permission `roles/logging.logWriter`

### Decrypt encrypted metadata
```sh
gcloud compute instances describe kms-server \
--zone asia-east2-a  \
--format 'value[](metadata.items.password)' \
| base64 -d \
| gcloud kms decrypt \
--keyring kms-keyring \
--key kms-secret-ce214739 \
--location asia-east2 \
--ciphertext-file - \ 
--plaintext-file -
```

### OpenAM Keystore

Keystore: https://backstage.forgerock.com/docs/am/6/maintenance-guide/#about-default-keystores

```sh
keytool -keystore ./WEB-INF/template/keystore/keystore.jceks -storepass changeit -list
```

### Links
* https://backstage.forgerock.com/docs/amster/6/user-guide/#private-login
* https://idmdude.com/2014/02/09/how-to-configure-openam-signing-keys/
* https://backstage.forgerock.com/docs/am/6.5/install-guide/#sec-startup-openam-java-properties
