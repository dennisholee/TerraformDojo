resource "google_compute_instance" "bastion_server" {
  name                      = "${var.bastion_server-name}"
  machine_type              = "${var.bastion_server-machine_type}"
  zone                      = "${var.bastion_server-zone}"
  can_ip_forward            = true
  allow_stopping_for_update = true
  count                     = 1

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
}
