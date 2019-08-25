# ------------------------------------------------------------------------------
# Network
# ------------------------------------------------------------------------------

output "my-internal-network" { value = google_compute_network.my-internal-network.self_link }

output "my-idmz-network"     { value = google_compute_network.my-idmz-network.self_link }

output "my-edmz-network"     { value = google_compute_network.my-edmz-network.self_link }

# ------------------------------------------------------------------------------
# Subnetwork
# ------------------------------------------------------------------------------

output "my-priv-subnet"      { value = google_compute_subnetwork.my-pri-subnet.self_link }

output "my-mgnt-subnet"      { value = google_compute_subnetwork.my-mgnt-subnet.self_link }

output "my-internal-subnet"  { value = google_compute_subnetwork.my-internal-subnet.self_link }

output "my-idmz-subnet"      { value = google_compute_subnetwork.my-idmz-subnet.self_link }

output "my-edmz-subnet"      { value = google_compute_subnetwork.my-edmz-subnet.self_link }

# ------------------------------------------------------------------------------
# Firewall
# ------------------------------------------------------------------------------

