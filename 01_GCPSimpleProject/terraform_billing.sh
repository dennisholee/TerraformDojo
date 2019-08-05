#!/bin/bash

account_id=$(gcloud beta billing accounts list --format='value(ACCOUNT_ID)')
gcloud beta billing projects link ${TF_ADMIN} --billing-account ${account_id}
