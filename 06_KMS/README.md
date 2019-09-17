# KMS Demo


```sh
gcloud kms keys list --location asia-east2 --keyring projects/foo789-terraform-admin/locations/asia-east2/keyRings/keyring-example --format=json
[
  {
    "createTime": "2019-09-17T16:28:44.040552306Z",
    "name": "projects/foo789-terraform-admin/locations/asia-east2/keyRings/keyring-example/cryptoKeys/kms-secret",
    "primary": {
      "algorithm": "GOOGLE_SYMMETRIC_ENCRYPTION",
      "createTime": "2019-09-17T16:28:44.040552306Z",
      "generateTime": "2019-09-17T16:28:44.040552306Z",
      "name": "projects/foo789-terraform-admin/locations/asia-east2/keyRings/keyring-example/cryptoKeys/kms-secret/cryptoKeyVersions/1",
      "protectionLevel": "SOFTWARE",
      "state": "ENABLED"
    },
    "purpose": "ENCRYPT_DECRYPT",
    "versionTemplate": {
      "algorithm": "GOOGLE_SYMMETRIC_ENCRYPTION",
      "protectionLevel": "SOFTWARE"
    }
  }
```

```sh
cloud kms keys get-iam-policy kms-secret --location asia-east2   --keyring keyring-example
bindings:
- members:
  - serviceAccount:kms-sa@foo789-terraform-admin.iam.gserviceaccount.com
  role: roles/cloudkms.cryptoKeyEncrypterDecrypter
etag: BwWSwkLV6jQ=
version: 1
```

