resource "google_compute_network" "cloudcomputing_vpc" {


  name                    = "var.network_name"
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name          = var.webapp_subnet_name
  ip_cidr_range = var.webapp_subnet_cidr
  region        = var.region
  network       = google_compute_network.cloudcomputing_vpc.self_link
}

resource "google_compute_subnetwork" "db_subnet" {
  name          = var.db_subnet_name
  ip_cidr_range = var.db_subnet_cidr
  region        = var.region
  network       = google_compute_network.cloudcomputing_vpc.self_link
}

resource "google_compute_instance" "vm_CloudComputing" {
  name         = var.vm_name
  machine_type = var.vm_machine_type
  zone         = var.zone 
  boot_disk {
    initialize_params {
      image = var.vm_disk_image
      size  = 100
      type  = var.vm_disk_type
    }
  }
network_interface {
    network = var.vm_network
    access_config {
        
    }
  }

  metadata_startup_script = "echo hi > /test.txt"
  allow_stopping_for_update = true

  tags = ["http-server", "https-server"]
}
