#!/bin/bash

gcloud projects create ${TF_ADMIN} \
#  --organization ${TF_VAR_org_id} \
#  --set-as-default

#gcloud beta billing projects link ${TF_ADMIN} \
#  --billing-account ${TF_VAR_billing_account}
