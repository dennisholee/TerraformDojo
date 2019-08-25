resource "google_compute_instance" "testbox_server" {
  name                      = "${var.testbox_server-name}"
  machine_type              = "${var.testbox_server-machine_type}"
  zone                      = "${var.testbox_server-zone}"
  can_ip_forward            = true
  allow_stopping_for_update = true
  count                     = 1

  // Adding METADATA Key Value pairs to WEB SERVER 
 # metadata {
   # startup-script-url = "${var.testbox_startup_script_bucket}"
   # serial-port-enable = true

    # sshKeys                              = "${var.public_key}"
#  }

  service_account {
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = "${var.testbox_server-subnet}"
    # address    = "${var.ip_testbox}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9" # "${var.image_testbox}"
    }
  }

  tags = var.testbox_server-tags

#  depends_on = [
  #  "${var.testbox_server-subnet}",
 #  "google_compute_network.my-testbox-subnet"
   # "google_compute_network.testbox",
   # "google_compute_network.db",
   # "google_compute_network.untrust",
   # "google_compute_network.management",
#  ]
}
