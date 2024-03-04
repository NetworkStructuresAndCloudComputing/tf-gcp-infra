resource "google_compute_firewall" "cloudcomputing_firewall" {
  name    = var.vm_firewall
  network = google_compute_network.cloudcomputing_vpc.self_link

  allow {
    protocol = var.firewall_protocol
    ports    = [var.firewall_ports, "3306"]
  }

  source_ranges = [var.firewall_source_ranges,google_compute_subnetwork.webapp_subnet.ip_cidr_range]
}

resource "google_compute_firewall" "cloudcomputing_firewall2" {
  name    = var.vm_firewall_two
  network = google_compute_network.cloudcomputing_vpc.self_link

  deny {
    protocol = var.firewall_protocol
    ports    = [ "22"]
  }

  source_ranges = [var.firewall_source_ranges,google_compute_subnetwork.webapp_subnet.ip_cidr_range]
}
