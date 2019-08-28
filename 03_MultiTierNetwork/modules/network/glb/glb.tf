resource "google_compute_global_address" "public-ip-address" {
  name         = "${var.glb-address_name}"
  ip_version   = "IPV4"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "fwd-rule" {
  name       = "${var.glb-fwd_rule_name}"
  target     = "${google_compute_target_http_proxy.http-proxy.self_link}"
  port_range = "${var.glb-fwd_rule_port_range}"
}

resource "google_compute_target_http_proxy" "http-proxy" {
  name        = "${var.glb-https_proxy_name}"
  description = "a description"
  url_map     = "${google_compute_url_map.url-mapper.self_link}"
}

resource "google_compute_url_map" "url-mapper" {
  name            = "${var.glb-url_mapper_name}"
  default_service = "${google_compute_backend_service.backend-service.self_link}"

  host_rule {
    hosts        = ["mysite.com"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = "${google_compute_backend_service.backend-service.self_link}"

    path_rule {
      paths   = ["/*"]
      service = "${google_compute_backend_service.backend-service.self_link}"
    }
  }
}

resource "google_compute_backend_service" "backend-service" {
  name        = "${var.glb-backend_service_name}"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = "${var.glb-compute_instance_group}"
  }

#  health_checks = ["${google_compute_http_health_check.health_check.self_link}"]
  health_checks = var.glb-health_check 
}

resource "google_compute_http_health_check" "health_check" {
  name               = "check-backend"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}
