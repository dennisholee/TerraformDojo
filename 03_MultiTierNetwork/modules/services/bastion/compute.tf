resource "google_compute_instance" "bastion_server" {
  name                      = "${var.bastion_server-name}"
  machine_type              = "${var.bastion_server-machine_type}"
  zone                      = "${var.bastion_server-zone}"
  can_ip_forward            = true
  allow_stopping_for_update = true
  count                     = 1

  // Adding METADATA Key Value pairs to WEB SERVER 
 # metadata {
   # startup-script-url = "${var.web_startup_script_bucket}"
   # serial-port-enable = true

    # sshKeys                              = "${var.public_key}"
#  }

  service_account {
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = "${var.bastion_server-subnet}"
    access_config { }
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9" # "${var.image_web}"
    }
  }

  tags = var.bastion_server-tags

#  depends_on = [
  #  "${var.bastion_server-subnet}",
 #  "google_compute_network.my-bastion-subnet"
   # "google_compute_network.web",
   # "google_compute_network.db",
   # "google_compute_network.untrust",
   # "google_compute_network.management",
#  ]
}
