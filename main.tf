provider "google" {
  credentials = file(var.GOOGLE_CREDENTIALS)
  project     = var.project_id
  region      = var.region
}
resource "google_compute_network" "cloudcomputing_vpc" {
  name                    = var.network_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
  
}

resource "google_compute_subnetwork" "webapp_subnet" {
  name                     = var.webapp_subnet_name
  ip_cidr_range            = var.webapp_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.cloudcomputing_vpc.self_link
}

resource "google_compute_subnetwork" "db_subnet" {
  name                     = var.db_subnet_name
  ip_cidr_range            = var.db_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.cloudcomputing_vpc.self_link
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
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link
    access_config {}
  }
}

# resource "google_compute_global_address" "default" {
#   provider     = google-beta
#   project      = var.project_id
#   name         = "global-psconnect-ip"
#   address_type = "INTERNAL"
#   purpose      = "VPC_PEERING"
#   address      = "10.3.0.5"
#   network      = google_compute_network.cloudcomputing_vpc.id
# }

# resource "google_service_networking_connection" "default" {
#   depends_on             = [google_compute_global_address.default]
#   network                 = google_compute_network.cloudcomputing_vpc.id
#   service                 = "servicenetworking.googleapis.com"
#   reserved_peering_ranges = [google_compute_global_address.default.name]
# }



# resource "google_sql_database_instance" "cloudsql_instance" {
#   name             = var.cloudsql_instance_name
#   database_version = var.cloudsql_database_version
#   project          = var.project_id
#   region           = var.region
#   deletion_protection = var.deletion_protection
#   settings {
#     tier = var.cloudsql_tier
#     ip_configuration {
#       ipv4_enabled = var.cloudsql_ipv4_enabled
#       private_network = google_compute_network.cloudcomputing_vpc.self_link
#     }
#      availability_type  = var.availability_type
#      disk_type          = var.cloudsql_disk_type
#      disk_size          = var.cloudsql_disk_size  
#   }
# }