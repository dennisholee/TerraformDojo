resource "google_compute_instance_template" "web-group" {
  name        = "appserver-template"

  tags = var.web_group-tags

#  labels = {
#    environment = var.web_group-environment
#  }

  machine_type         = "f1-micro"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  // Create a new boot disk from an image
  disk {
    source_image = data.google_compute_image.web-image.self_link # "debian-cloud/debian-9"
    auto_delete  = true
    boot         = true
  }

#   // Use an existing disk resource
#   disk {
#     // Instance Templates reference disks by name, not self link
#     source      = "${data.google_compute_disk.web-disk.name}"
#     auto_delete = false
#     boot        = false
#   }

  network_interface {
    subnetwork = "${var.web_group-subnetwork}"
  }

  metadata = {
    foo = "bar"
  }

  service_account {
    scopes = []
  }
}

# resource "google_compute_disk" "web-disk" {
#   name  = "web-disk"
#   image = "${data.google_compute_image.web-image.self_link}"
#   size  = 10
#   type  = "pd-ssd"
# }

data "google_compute_image" "web-image" {
  family  = "my-web-server-image"
  project = "foo789-terraform-admin"
}

# ------------------------------------------------------------------------------
# Create instance group
# ------------------------------------------------------------------------------

resource "google_compute_health_check" "autohealing" {
  name                = "autohealing-health-check"
  check_interval_sec  = 30
  timeout_sec         = 30
  healthy_threshold   = 2
  unhealthy_threshold = 10

  http_health_check {
    request_path = "/"
    port         = "80"
  }
}

resource "google_compute_region_instance_group_manager" "web-server" {
  name = "webserver-igm"

  base_instance_name = "app"
  instance_template  = "${google_compute_instance_template.web-group.self_link}"
#  update_strategy    = "NONE"
  region             = "europe-west2"

#  target_pools = ["${google_compute_target_pool.appserver.self_link}"]
  target_size  = 2

#  named_port {
#    name = "customHTTP"
#    port = 80
#  }

  auto_healing_policies {
    health_check      = "${google_compute_health_check.autohealing.self_link}"
    initial_delay_sec = 300
  }
}


# resource "google_compute_instance" "web_server" {
#   name                      = "${var.web_server-name}"
#   machine_type              = "${var.web_server-machine_type}"
#   zone                      = "${var.web_server-zone}"
#   can_ip_forward            = true
#   allow_stopping_for_update = true
#   count                     = 1
# 
#   // Adding METADATA Key Value pairs to WEB SERVER 
#  # metadata {
#    # startup-script-url = "${var.web_startup_script_bucket}"
#    # serial-port-enable = true
# 
#     # sshKeys                              = "${var.public_key}"
# #  }
# 
#   service_account {
#     scopes = ["cloud-platform"]
#   }
# 
#   network_interface {
#     subnetwork = "${var.web_server-subnet}"
#     # address    = "${var.ip_web}"
#   }
# 
#   boot_disk {
#     initialize_params {
#       image = "debian-cloud/debian-9" # "${var.image_web}"
#     }
#   }
# 
#   tags = var.web_server-tags
# 
# #  depends_on = [
#   #  "${var.web_server-subnet}",
#  #  "google_compute_network.my-web-subnet"
#    # "google_compute_network.web",
#    # "google_compute_network.db",
#    # "google_compute_network.untrust",
#    # "google_compute_network.management",
# #  ]
# }
