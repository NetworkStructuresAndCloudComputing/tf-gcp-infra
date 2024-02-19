resource "google_compute_firewall" "cloudcomputing_firewall" {
  name    = var.vm_firewall
  network = google_compute_network.cloudcomputing_vpc.self_link

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_ranges = ["0.0.0.0/0"]
}
