resource "google_compute_instance" "mgnt_server" {
  name                      = "${var.mgnt_server-name}"
  machine_type              = "${var.mgnt_server-machine_type}"
  zone                      = "${var.mgnt_server-zone}"
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
    subnetwork = "${var.mgnt_server-subnet}"
    # address    = "${var.ip_web}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9" # "${var.image_web}"
    }
  }

#  depends_on = [
  #  "${var.mgnt_server-subnet}",
 #  "google_compute_network.my-mgnt-subnet"
   # "google_compute_network.web",
   # "google_compute_network.db",
   # "google_compute_network.untrust",
   # "google_compute_network.management",
#  ]
}
