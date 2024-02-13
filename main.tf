provider "google" {
  credentials = file("/Users/zakirmemon/Downloads/cloudcomputing-414020-d5bd516e8358.json")
 project     = var.project_id
  region      = var.region
}

resource "google_compute_network" "cloudcomputing_vpc" {
  name                    = "cloudcomputing"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = "webapp"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-east1"
  network       = google_compute_network.cloudcomputing_vpc.self_link
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = "db"
  ip_cidr_range = "10.0.2.0/24"
  region        = "us-east1"
  network       = google_compute_network.cloudcomputing_vpc.self_link
}
