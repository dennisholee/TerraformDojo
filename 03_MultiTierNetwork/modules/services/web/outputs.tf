output "compute-instance-group" { value = google_compute_region_instance_group_manager.web-server.instance_group }

output "health-check" { value = google_compute_health_check.autohealing.self_link }
