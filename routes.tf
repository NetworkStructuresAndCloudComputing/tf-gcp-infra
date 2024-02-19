resource "google_compute_route" "default_route" {
  name               = var.default_route_name
  network            = google_compute_network.cloudcomputing_vpc.self_link
  dest_range         = var.route_dest_range
  next_hop_gateway    = var.route_next_hop_gateway
}