resource "google_compute_instance" "squid_server" {
  name                      = "${var.squid_server-name}"
  machine_type              = "${var.squid_server-machine_type}"
  zone                      = "${var.squid_server-zone}"
  can_ip_forward            = true
  allow_stopping_for_update = true
  count                     = 1

  // Adding METADATA Key Value pairs to WEB SERVER 
 # metadata {
   # startup-script-url = "${var.squid_startup_script_bucket}"
   # serial-port-enable = true

    # sshKeys                              = "${var.public_key}"
#  }

  service_account {
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = "${var.squid_server-subnet}"
    # address    = "${var.ip_squid}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9" # "${var.image_squid}"
    }
  }

  tags = var.squid_server-tags

  metadata_startup_script = "sudo apt-get update; sudo apt-get install squid -y"

#  depends_on = [
  #  "${var.squid_server-subnet}",
 #  "google_compute_network.my-squid-subnet"
   # "google_compute_network.squid",
   # "google_compute_network.db",
   # "google_compute_network.untrust",
   # "google_compute_network.management",
#  ]
}
