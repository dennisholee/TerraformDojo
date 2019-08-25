#export TF_VAR_org_id=YOUR_ORG_ID
#export TF_VAR_billing_account=YOUR_BILLING_ACCOUNT_ID
#export TF_ADMIN=${USER}-terraform-admin
#export TF_CREDS=~/.config/gcloud/${USER}-terraform-admin.json

#export TF_VAR_gcp_project=foo789-terraform-admin

#gcloud organizations list
#gcloud beta billing accounts list

# Setup SSH

https://cloud.google.com/compute/docs/instances/connecting-advanced#sshbetweeninstances

ssh-add ~/.ssh/[PRIVATE_KEY]
Add `-A` argument to enable authentication agent forwarding

ssh -A [USERNAME]@[BASTION_HOST_EXTERNAL_IP_ADDRESS]

ssh [USERNAME]@[INTERNAL_INSTANCE_IP_ADDRESS]

# Environment variables
export GOOGLE_APPLICATION_CREDENTIALS=${JSON_FILE}
export TF_VAR_public_key=${KEY_PATH}
