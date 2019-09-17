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

# Insufficient Permission Error Example
```sh
> node app.js 
Error: Permission 'cloudkms.cryptoKeyVersions.useToEncrypt' denied for resource 'projects/foo789-terraform-admin/locations/asia-east2/keyRings/keyring-example/cryptoKeys/kms-secret'.
    at Http2CallStream.<anonymous> (/Users/dennislee/Devs/Terraform/TerraformDojo/06_KMS/app/node_modules/@grpc/grpc-js/build/src/client.js:96:45)
    at Http2CallStream.emit (events.js:214:15)
    at /Users/dennislee/Devs/Terraform/TerraformDojo/06_KMS/app/node_modules/@grpc/grpc-js/build/src/call-stream.js:71:22
    at processTicksAndRejections (internal/process/task_queues.js:75:11) {
  code: 7,
  details: "Permission 'cloudkms.cryptoKeyVersions.useToEncrypt' denied for resource 'projects/foo789-terraform-admin/locations/asia-east2/keyRings/keyring-example/cryptoKeys/kms-secret'.",
  metadata: Metadata {
    options: undefined,
    internalRepr: Map { 'grpc-server-stats-bin' => [Array] }
  },
  note: 'Exception occurred in retry method that was not classified as transient'
}
```
