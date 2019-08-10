resource "google_compute_instance" "appserver" {
  name = "primary-application-server"
  zone = "europe-west2-a"
  machine_type = "f1-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = "${var.my-vpc-internal}"  
  }

  service_account {
    scopes = ["cloud-platform"]
  }
}
