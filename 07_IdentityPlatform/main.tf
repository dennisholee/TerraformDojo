#terraform {
#  required_version = ">= 0.12.7"
#}

provider "google" {
  project = "${var.project_id}"
}

locals {
  app           = "kms"
  terraform     = "terraform"
  zone          = "asia-east2-a"
  region        = "asia-east2"
  ip_cidr_range = "192.168.0.0/24"

  bucket        = "foo789-terraform-admin-software"
  openam        = "AM-6.5.2.1"
  openamtool    = "AM-SSOAdminTools-5.1.2.11"
  amster        = "Amster-6.5.2.1"
  tomcat        = "apache-tomcat-9.0.26"
}

# ------------------------------------------------------------------------------
# Adding SSH Public Key in Project Meta Data
# ------------------------------------------------------------------------------

resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "dennislee:${file("${var.public_key}")}"
}

# -------------------------------------------------------------------------------
# Service account
# -------------------------------------------------------------------------------

resource "google_service_account" "sa" {
  account_id = "${local.app}-sa"
}

resource "google_project_iam_binding" "sa-networkviewer-iam" {
  role   = "roles/compute.networkViewer"
  members = ["serviceAccount:${google_service_account.sa.email}"]
}

resource "google_project_iam_binding" "sa-cryptokeyencrypterdecrypter-iam" {
  role   = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = ["serviceAccount:${google_service_account.sa.email}", "serviceAccount:${local.terraform}@${var.project_id}.iam.gserviceaccount.com"]
}


resource "google_project_iam_binding" "sa-cloudstorage-iam" {
  role   = "roles/storage.objectViewer"
  members = ["serviceAccount:${google_service_account.sa.email}"]
}


# -------------------------------------------------------------------------------
# Network
# -------------------------------------------------------------------------------

resource "google_compute_network" "vpc" {
  name                    = "${local.app}-network"
  auto_create_subnetworks = "false"
}

resource "google_compute_subnetwork" "subnet" {
  name                     = "${local.app}-subnet"
  region                   = "${local.region}"
  ip_cidr_range            = "${local.ip_cidr_range}"
  network                  = "${google_compute_network.vpc.self_link}"
  private_ip_google_access = true
}

# -------------------------------------------------------------------------------
# Firewall
# -------------------------------------------------------------------------------

resource "google_compute_firewall" "firewall" {
  name          = "fw-${local.app}-ssh"
  network       = "${google_compute_network.vpc.self_link}"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  
  allow {
    protocol = "tcp"
    ports    = ["22", "80", "8080"]
  }

  target_tags = ["fw-${local.app}-ssh"]
}

# -------------------------------------------------------------------------------
# Compute Engine
# -------------------------------------------------------------------------------

resource "google_compute_instance" "server" {
  name                      = "${local.app}-server"
  machine_type              = "n1-standard-2"
  zone                      = "${local.zone}"
  count                     = 1
  
  metadata = {
    sshKeys  = "dennislee:${file("${var.public_key}")}"
    foo      = "acme"
    key      = "${google_kms_crypto_key.secret-key.self_link}"
    password = "${data.google_kms_secret_ciphertext.cipher_password.ciphertext}"
  }

  service_account {
    email   = "${google_service_account.sa.email}"
    scopes  = ["cloud-platform"]
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.subnet.self_link}"
    access_config { }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  metadata_startup_script = <<SCRIPT
sudo apt-get update
# Decrypt key
echo "--------------------"
export KEY=$(gcloud compute instances describe kms-server --zone ${local.zone} --format 'value[](metadata.items.key)')
echo "* KEY : $KEY"
export PASSWORD_CIPHER=$(gcloud compute instances describe kms-server --zone ${local.zone}  --format 'value[](metadata.items.password)')
echo "* PASSWORD_CIPHER: $PASSWORD_CIPHER"
echo $PASSWORD_CIPHER | base64 -d | gcloud kms decrypt --keyring kms-keyring --key $KEY --location asia-east2 --ciphertext-file - --plaintext-file -
echo -e "\n--------------------"
# Install openam
sudo apt-get install -y openjdk-11-jdk
sudo apt-get install -y unzip
cd /opt
# Assumes all binaries are available on cloud storage
gsutil cp gs://${local.bucket}/${local.openam}.war .
gsutil cp gs://${local.bucket}/${local.openamtool}.zip .
gsutil cp gs://${local.bucket}/${local.amster}.zip .
gsutil cp gs://${local.bucket}/${local.tomcat}.tar.gz .
tar xf ${local.tomcat}.tar.gz
unzip ${local.amster}.zip
unzip ${local.openamtool}.zip -d ${local.openamtool}
echo "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/" >> /etc/profile
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/
mv ${local.openam}.war ./${local.tomcat}/webapps/
./${local.tomcat}/bin/startup.sh
cat <<EOF >init_openam.sh
install-openam --serverUrl http://$(hostname -f):8080/${local.openam} --adminPwd password --acceptLicense
# TODO: Need to enable key authentication for the below to work
connect --private-key /root/openam/amster_rsa http://$(hostname -f):8080/${local.openam}
create Realms --global --body "{ \"name\" : \"SMEP\", \"active\" : true, \"parentPath\" : \"\/\", \"aliases\" : [\"smep.local\"]  }"
EOF
./amster init_openam.sh
cd ${local.openamtool}
./setup --acceptLicense --path /root/openam/
# TODO: Encrypt /root/openam/${local.openam}/.storepass and /root/openam/${local.openam}/.keypass
# Hints: Use the plain text password obtained after decryption from Cloud KMS
# Hints: Ensure keystore passphase is aligned
# /opt/${local.openamtool}/${local.openam}/bin/ampassword -encrypt <plaintext_file> <cipher_file>
SCRIPT

  tags = ["${google_compute_firewall.firewall.name}"] 
}

# -------------------------------------------------------------------------------
# Encryption key
# -------------------------------------------------------------------------------

resource "random_id" "key_name_suffix" {
  byte_length = 4
}


# resource "google_kms_key_ring" "keyring" {
#   name = "${local.app}-keyring"
#   location = "${local.region}"
# }

data "google_kms_key_ring" "keyring" {
  name = "${local.app}-keyring"
  location = "${local.region}"
}

resource "google_kms_crypto_key" "secret-key" {
   name            = "${local.app}-secret-${random_id.key_name_suffix.hex}"
   key_ring        = "${data.google_kms_key_ring.keyring.self_link}"
}

#data "google_kms_crypto_key" "secret-key" {
#  name            = "${local.app}-secret"
#  key_ring        = "${data.google_kms_key_ring.keyring.self_link}"
#}

resource "google_kms_crypto_key_iam_binding" "secret-key-iam-binding" {
  crypto_key_id = "${google_kms_crypto_key.secret-key.self_link}"
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members       = ["serviceAccount:${google_service_account.sa.email}", "serviceAccount:${local.terraform}@${var.project_id}.iam.gserviceaccount.com"]
}


# -------------------------------------------------------------------------------
# Ciphered data
# -------------------------------------------------------------------------------

resource "random_password" "password" {
  length = 16
}

data "google_kms_secret_ciphertext" "cipher_password" {
  crypto_key = "${google_kms_crypto_key.secret-key.self_link}"
  plaintext  = random_password.password.result
  depends_on = ["google_project_iam_binding.sa-cryptokeyencrypterdecrypter-iam"]
}
