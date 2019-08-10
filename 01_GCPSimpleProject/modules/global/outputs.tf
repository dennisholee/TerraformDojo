output "my-vpc-internal" {
  value = google_compute_subnetwork.my-vpc-internal.self_link
}
