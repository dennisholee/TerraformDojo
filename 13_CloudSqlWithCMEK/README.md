
> Note: To create a servicef account with the required permissions, you must have resourcemanager.projects.setIamPolicy permission. 
> This permission is included in the Project Owner, Project IAM Admin, and Organization Administrator roles.
> 
> You must also enable the Cloud SQL Admin API.
> 
> Src: https://cloud.google.com/sql/docs/postgres/configure-cmek

```
# 1. Create service identity for CloudSQL
gcloud alpha services identity create --service sqladmin.googleapis.com

# 2. Enable cloud kms API
gcloud services enable cloudkms.googleapis.com

# 3. Create key ring
gcloud kms keyrings create foo-keyring --location asia-east2

# 4. Create key
gcloud kms keys create foo-key --location asia-east2 --keyring foo-keyring --purpose encryption

# 5. Grant cloud sql service identity access to key 
gcloud kms keys add-iam-policy-binding foo-key --location asia-east2 --keyring foo-keyring --member serviceAccount:service-944813120763@gcp-sa-cloud-sql.iam.gserviceaccount.com --role roles/cloudkms.cryptoKeyEncrypterDecrypter
Updated IAM policy for key [foo-key].
bindings:
- members:
  - serviceAccount:service-944813120763@gcp-sa-cloud-sql.iam.gserviceaccount.com
  role: roles/cloudkms.cryptoKeyEncrypterDecrypter
etag: BwWeN8OA8uI=
version: 1

# 6. Create cloud sql instance with CMEK enabled
gcloud sql instances create foo-db --disk-encryption-key projects/playground-s-11-416253/locations/asia-east2/keyRings/foo-keyring/cryptoKeys/foo-key --database-version POSTGRES_11 --region asia-east2 --cpu 2 --memory 4

gcloud sql instances describe foo-db --format="json(diskEncryptionStatus,ipAddresses)"
{
  "diskEncryptionStatus": {
    "kind": "sql#diskEncryptionStatus",
    "kmsKeyVersionName": "projects/playground-s-11-416253/locations/asia-east2/keyRings/foo-keyring/cryptoKeys/foo-key/cryptoKeyVersions/1"
  },
  "ipAddresses": [
    {
      "ipAddress": "34.92.147.40",
      "type": "PRIMARY"
    }
  ]
}
```

Create service identity via a service account

```
# 1. Enable APIs
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable serviceusage.googleapis.com
gcloud services enable sqladmin.googleapis.com

# 2. Bind role to service account
gcloud projects add-iam-policy-binding playground-s-11-416253 --member serviceAccount:terraform@playground-s-11-416253.iam.gserviceaccount.com --role=roles/viewer

# 3. Create service identity
# Fails even if owner permission is granted to service account however upon switching to a user account it run successfully under same console.
gcloud alpha services identity create --service=sqladmin.googleapis.com --project playground-s-11-416253
ERROR: (gcloud.beta.services.identity.create) NOT_FOUND: Method not found.

```

Debug log

```sh
# Service account
DEBUG: (gcloud.beta.services.identity.create) NOT_FOUND: Method not found.
Traceback (most recent call last):
  File "/google/google-cloud-sdk/lib/googlecloudsdk/calliope/cli.py", line 981, in Execute
    resources = calliope_command.Run(cli=self, args=args)
  File "/google/google-cloud-sdk/lib/googlecloudsdk/calliope/backend.py", line 807, in Run
    resources = command_instance.Run(args)
  File "/google/google-cloud-sdk/lib/surface/services/identity/create.py", line 65, in Run
    email, _ = serviceusage.GenerateServiceIdentity(project, args.service)
  File "/google/google-cloud-sdk/lib/googlecloudsdk/api_lib/services/serviceusage.py", line 267, in GenerateServiceIdentity
    e, exceptions.GenerateServiceIdentityPermissionDeniedException)
  File "/google/google-cloud-sdk/lib/googlecloudsdk/api_lib/services/exceptions.py", line 75, in ReraiseError
    core_exceptions.reraise(klass(api_lib_exceptions.HttpException(err)))
  File "/google/google-cloud-sdk/lib/googlecloudsdk/core/exceptions.py", line 146, in reraise
    six.reraise(type(exc_value), exc_value, tb)
  File "/google/google-cloud-sdk/lib/googlecloudsdk/api_lib/services/serviceusage.py", line 261, in GenerateServiceIdentity
    op = client.services.GenerateServiceIdentity(request)
  File "/google/google-cloud-sdk/lib/googlecloudsdk/third_party/apis/serviceusage/v1beta1/serviceusage_v1beta1_client.py", line 230, in GenerateServiceIdentity
    config, request, global_params=global_params)
  File "/google/google-cloud-sdk/lib/third_party/apitools/base/py/base_api.py", line 731, in _RunMethod
    return self.ProcessHttpResponse(method_config, http_response, request)
  File "/google/google-cloud-sdk/lib/third_party/apitools/base/py/base_api.py", line 737, in ProcessHttpResponse
    self.__ProcessHttpResponse(method_config, http_response, request))
  File "/google/google-cloud-sdk/lib/third_party/apitools/base/py/base_api.py", line 604, in __ProcessHttpResponse
    http_response, method_config=method_config, request=request)
GenerateServiceIdentityPermissionDeniedException: NOT_FOUND: Method not found.
ERROR: (gcloud.beta.services.identity.create) NOT_FOUND: Method not found.
```

```sh
# User account
DEBUG: Running [gcloud.beta.services.identity.create] with arguments: [--service: "sqladmin.googleapis.com", --verbosity: "debug"]
Service identity created: service-446997833361@gcp-sa-cloud-sql.iam.gserviceaccount.com
INFO: Display format: "none"
DEBUG: SDK update checks are disabled.
```
