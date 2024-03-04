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
  private_ip_google_access = true
}

resource "google_compute_subnetwork" "db_subnet" {
  name                     = var.db_subnet_name
  ip_cidr_range            = var.db_subnet_cidr
  region                   = var.region
  network                  = google_compute_network.cloudcomputing_vpc.self_link
  private_ip_google_access = true
}


resource "google_compute_global_address" "default" {
  project      = var.project_id
  name         = var.global_address_name
  address_type = var.address_type
  purpose      = var.global_address_purpose
  prefix_length = 24 
  network      = google_compute_network.cloudcomputing_vpc.id
}

resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.cloudcomputing_vpc.id
  service                 = var.network_service
  reserved_peering_ranges = [google_compute_global_address.default.name]
  deletion_policy = var.deletion_policy
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "cloudsql_instance" {
  name             = "db-instance-${random_id.db_name_suffix.hex}"
  database_version = var.cloudsql_database_version
  project          = var.project_id
  region           = var.region
  deletion_protection = var.deletion_protection
  depends_on = [ google_service_networking_connection.default ]
  settings {
    tier = var.cloudsql_tier
    ip_configuration {
      ipv4_enabled = var.cloudsql_ipv4_enabled
      private_network = google_compute_network.cloudcomputing_vpc.self_link
    }
    backup_configuration {
      enabled = true
      binary_log_enabled = true    
    }
     availability_type  = var.availability_type
     disk_type          = var.cloudsql_disk_type
     disk_size          = var.cloudsql_disk_size  
  }
}

resource "google_sql_database" "cloud_computing_db" {
  name     = var.cloudsql_database
  instance = google_sql_database_instance.cloudsql_instance.name
}
resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_%@"
}
resource "google_sql_user" "users" {
  name     = var.sql_name
  instance = google_sql_database_instance.cloudsql_instance.name
  password = random_password.password.result
  host     = "%"
  depends_on = [google_sql_database.cloud_computing_db]
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

metadata_startup_script = <<-EOT
  #!/bin/bash

  set -e
  echo "Hello World!"
  

  env_file="/home/webapp/.env"

  echo "DATABASE_NAME=${google_sql_database.cloud_computing_db.name}" >> "$env_file"
  echo "HOST=${google_sql_database_instance.cloudsql_instance.ip_address.0.ip_address}" >> "$env_file"
  echo "DATABASE_USERNAME=${google_sql_user.users.name}" >> "$env_file"
  echo "DATABASE_PASSWORD=${google_sql_user.users.password}" >> "$env_file"
  echo "PORT=3306" >> "$env_file"
  EOT
}
