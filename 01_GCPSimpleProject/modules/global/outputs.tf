output "my-vpc-internal" {
  value = google_compute_subnetwork.my-vpc-internal.self_link
}

output "my-vpc-dmz" {
  value = google_compute_subnetwork.my-vpc-dmz.self_link
}
