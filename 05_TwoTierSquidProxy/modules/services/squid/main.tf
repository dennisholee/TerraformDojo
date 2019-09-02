resource "google_compute_instance" "squid_server" {
  name                      = "${var.squid_server-name}"
  machine_type              = "${var.squid_server-machine_type}"
  zone                      = "${var.squid_server-zone}"
  can_ip_forward            = true
  allow_stopping_for_update = true
  count                     = 1

  service_account {
    scopes = ["cloud-platform"]
  }

  network_interface {
    subnetwork = "${var.squid_server-primary_subnet}"
  }

  network_interface {
    subnetwork = "${var.squid_server-secondary_subnet}"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9" 
    }
  }

  tags = var.squid_server-tags

#   metadata_startup_script = <<SCRIPT
# sudo route del default
# sudo route add default gw ${var.squid_server-gw} ${var.squid_server-nic}
# sudo apt-get update
# sudo apt-get install squid3 -y
# sudo touch /etc/squid/AllowHosts.txt
# SCRIPT

  provisioner "remote-exec" {
    inline = [
      "sudo route del default",
      "sudo route add default gw ${var.squid_server-gw} ${var.squid_server-nic}",
      "sudo apt-get update",
      "sudo apt-get install squid3 -y",
      "sudo touch /etc/squid/AllowHosts.txt"
    ]
  }
}
