#

## Create terraform account.

```bash
export PROJECT_ID="..."

# Create service account.
gcloud iam service-accounts create terraform --description "terraform service account"

# Export service account key.
gcloud iam service-accounts keys create terraform-sa-key.json --iam-account="terraf
orm@${PROJECT_ID}.iam.gserviceaccount.com" --key-file-type json

# Enable Google APIs.
gcloud services enable \ 
  cloudbuild.googleapis.com \ 
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  cloudfunctions.googleapis.com
```


## Initialize terraform on GShell.

Create cloud storage bucket to backup terraform state.
```bash
gsutil mb gs://$(gcloud config get-value project)-tfstate
```

Create SSH Keys to connect to compute resources
```bash
# Note the location of the generate key will be used in the subsequent docker commands
ssh-keygen -t rsa -f /tmp/id_rsa.pub -q -N ""
```

```bash
docker run -v $(pwd):/app -w /app hashicorp/terraform:0.12.16 init

docker run -v $(pwd):/app \
  -v $(realpath terraform.tfvars):/terraform.tfvars \ 
  -v /tmp/id_rsa.pub:/tmp/id_rsa.pub \ 
  -e SSH_PRIVATE_KEY_FILE=/tmp/id_rsa.pub \ 
  -w /app hashicorp/terraform:0.12.16 apply --auto-approve
```
