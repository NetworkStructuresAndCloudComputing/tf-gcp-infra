resource "google_compute_route" "default_route" {
  name               = "default-route"
  network            = google_compute_network.cloudcomputing_vpc.self_link
  dest_range         = "0.0.0.0/0"
  next_hop_gateway    = "default-internet-gateway"
}