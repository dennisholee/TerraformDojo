resource "google_compute_instance" "router_server" {
  name                      = "${var.router_server-name}"
  machine_type              = "${var.router_server-machine_type}"
  zone                      = "${var.router_server-zone}"
  can_ip_forward            = true
  allow_stopping_for_update = true
  count                     = 1

  // Adding METADATA Key Value pairs to WEB SERVER 
 # metadata {
   # startup-script-url = "${var.router_startup_script_bucket}"
   # serial-port-enable = true

    # sshKeys                              = "${var.public_key}"
#  }

  service_account {
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = "${var.router_server-primary_subnet}"
  }

  network_interface {
    subnetwork = "${var.router_server-secondary_subnet}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9" # "${var.image_router}"
    }
  }

  tags = var.router_server-tags

  metadata_startup_script = "sudo apt-get update; sudo apt-get install router -y"

#  depends_on = [
  #  "${var.router_server-subnet}",
 #  "google_compute_network.my-router-subnet"
   # "google_compute_network.router",
   # "google_compute_network.db",
   # "google_compute_network.untrust",
   # "google_compute_network.management",
#  ]
}
