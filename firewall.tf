resource "google_compute_firewall" "cloudcomputing_firewall" {
  name    = var.vm_firewall
  network = google_compute_network.cloudcomputing_vpc.self_link

  allow {
    protocol = var.firewall_protocol
    ports    = [var.firewall_ports]
  }

  source_ranges = [var.firewall_source_ranges]
}
