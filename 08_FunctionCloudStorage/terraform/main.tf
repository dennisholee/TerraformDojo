#terraform {
#  required_version = ">= 0.12.7"
#}

provider "google" {
  project = "${var.project_id}"
}

locals {
  app           = "vision-bq"
  terraform     = "terraform"
  zone          = "asia-east2-a"
  region        = "asia-east2"

  bucket        = "${var.project_id}-${local.app}"
}

# ------------------------------------------------------------------------------
# Adding SSH Public Key in Project Meta Data
# ------------------------------------------------------------------------------

resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "dennislee:${file("${var.public_key}")}"
}

#-------------------------------------------------------------------------------
# Service Account
#-------------------------------------------------------------------------------

resource "google_service_account" "sa" {
  account_id   = "${local.app}-app-sa"
  display_name = "${local.app}-app-sa"
}

resource "google_project_iam_binding" "sa-pubsub-iam" {
  role   = "roles/pubsub.subscriber"
  members = ["serviceAccount:${google_service_account.sa.email}"]
}

resource "google_project_iam_binding" "sa-bucket-iam" {
  role   = "roles/storage.objectAdmin"
  members = ["serviceAccount:${google_service_account.sa.email}"]
}

resource "google_project_iam_binding" "sa-bigquery-iam" {
  role   = "roles/bigquery.dataOwner"
  members = ["serviceAccount:${var.project_id}@appspot.gserviceaccount.com"]
}

#-------------------------------------------------------------------------------
# PubSub
#-------------------------------------------------------------------------------

resource "google_pubsub_topic" "pub-bq-topic" {
  name = "${local.app}-pub-bq-topic"
}

resource "google_pubsub_subscription" "pub-bq-subscription" {
  name  = "${local.app}-pub-bq-subscription"
  topic = "${google_pubsub_topic.pub-bq-topic.name}"

  # 20 minutes
  message_retention_duration = "1200s"
  retain_acked_messages = true

  ack_deadline_seconds = 20

  expiration_policy {
    ttl = "300000.5s"
  }
}

# ------------------------------------------------------------------------------
# Cloud storage 
# ------------------------------------------------------------------------------

resource "google_storage_bucket" "image-bucket" {
  name     = "${local.bucket}"
  location = "${local.region}"
}

# ------------------------------------------------------------------------------
# Big Query
# ------------------------------------------------------------------------------

resource "google_bigquery_dataset" "dataset" {
  dataset_id                  = "${replace(local.app, "-", "_")}_dataset_id"
  friendly_name               = "${local.app}-dataset"
  description                 = "${local.app}-dataset"
  location                    = "${local.region}"
  default_table_expiration_ms = 3600000 # 60 minutes
}

resource "google_bigquery_table" "default" {
  dataset_id = "${google_bigquery_dataset.dataset.dataset_id}"
  table_id   = "bar"

  time_partitioning {
    type = "DAY"
  }

  schema = <<EOF
[
  {
    "name": "file",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "File name."
  },
  {
    "name": "landmark",
    "type": "STRING",
    "mode": "NULLABLE",
    "description": "Landmark."
  },
  {
    "name": "faces",
    "type": "INT64",
    "mode": "NULLABLE",
    "description": "Number of faces."
  }
]
EOF
}
