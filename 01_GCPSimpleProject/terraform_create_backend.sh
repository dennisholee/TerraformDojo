#!/bin/bash

gsutil mb -p ${TF_ADMIN} gs://${TF_ADMIN}

cat > backend.tf << EOF
terraform {
 backend "gcs" {
   bucket      = "${TF_ADMIN}"
   prefix      = "terraform/state"
   credentials = "${TF_CREDS}" 
 }
}
EOF
