resource "google_compute_instance" "web_server" {
  name                      = "${var.web_server-name}"
  machine_type              = "${var.web_server-machine_type}"
  zone                      = "${var.web_server-zone}"
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
    subnetwork = "${var.web_server-subnet}"
    # address    = "${var.ip_web}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9" # "${var.image_web}"
    }
  }

  tags = var.web_server-tags

#  depends_on = [
  #  "${var.web_server-subnet}",
 #  "google_compute_network.my-web-subnet"
   # "google_compute_network.web",
   # "google_compute_network.db",
   # "google_compute_network.untrust",
   # "google_compute_network.management",
#  ]
}
