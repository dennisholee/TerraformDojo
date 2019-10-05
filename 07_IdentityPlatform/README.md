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
