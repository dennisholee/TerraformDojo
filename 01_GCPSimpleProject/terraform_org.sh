# gcloud projects add-iam-policy-binding ${TF_ADMIN} \
#   --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
#   --role roles/resourcemanager.projectCreator

gcloud projects add-iam-policy-binding ${TF_ADMIN} \
  --member serviceAccount:terraform@${TF_ADMIN}.iam.gserviceaccount.com \
  --role roles/billing.user
