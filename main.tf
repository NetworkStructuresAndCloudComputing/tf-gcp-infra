provider "google" {
  credentials = file(var.GOOGLE_CREDENTIALS)
  project     = var.project_id
  region      = var.region
}

resource "google_service_account" "service_account" {
  account_id   = var.service_account_account_id
  display_name = var.service_account_display_name
}

# Bind IAM roles to the service account
resource "google_project_iam_binding" "logging_admin" {
  project = var.project_id
  role    = var.logging_admin_role

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "monitoring_metric_writer" {
  project = var.project_id
  role    = var.monitoring_metric_writern_role

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "logging_writer" {
  project = var.project_id
  role    = var.logging_writer_role

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
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
  project       = var.project_id
  name          = var.global_address_name
  address_type  = var.address_type
  purpose       = var.global_address_purpose
  prefix_length = 24
  network       = google_compute_network.cloudcomputing_vpc.id
}

resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.cloudcomputing_vpc.id
  service                 = var.network_service
  reserved_peering_ranges = [google_compute_global_address.default.name]
  deletion_policy         = var.deletion_policy
}

resource "random_id" "db_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "cloudsql_instance" {
  name                = "db-instance-${random_id.db_name_suffix.hex}"
  database_version    = var.cloudsql_database_version
  project             = var.project_id
  region              = var.region
  deletion_protection = var.deletion_protection
  depends_on          = [google_service_networking_connection.default]
  settings {
    tier = var.cloudsql_tier
    ip_configuration {
      ipv4_enabled    = var.cloudsql_ipv4_enabled
      private_network = google_compute_network.cloudcomputing_vpc.self_link
    }
    backup_configuration {
      enabled            = true
      binary_log_enabled = true
    }
    availability_type = var.availability_type
    disk_type         = var.cloudsql_disk_type
    disk_size         = var.cloudsql_disk_size
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
  name       = var.sql_name
  instance   = google_sql_database_instance.cloudsql_instance.name
  password   = random_password.password.result
  host       = "%"
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

  service_account {
    email  = google_service_account.service_account.email
    scopes = [var.service_account_scope, var.service_account_scope_role]
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

data "google_dns_managed_zone" "existing_zone" {
  name = var.existing_zone_name
}

resource "google_dns_record_set" "dns_record" {
  name         = var.dns_record_name
  type         = var.dns_record_type
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  rrdatas      = [google_compute_instance.vm_CloudComputing.network_interface.0.access_config.0.nat_ip]
}


resource "google_dns_record_set" "cname" {
  name         = "email.${var.dns_record_name_mx}"
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  type         = var.dns_record_type_cname
  ttl          = 300
  rrdatas      = [var.cname_rrdata]
}

resource "google_pubsub_topic" "verify_email_topic" {
  name                       = var.pubsub_topic_name
  message_retention_duration = var.retentation_duration
}

resource "google_pubsub_subscription" "verify_email_subscription" {
  name                 = var.pubsub_subscription_name
  topic                = google_pubsub_topic.verify_email_topic.name
  ack_deadline_seconds = 10
  expiration_policy {
    ttl = var.expiration_policy
  }
}

resource "google_pubsub_topic_iam_binding" "topic_publisher_binding" {
  topic = google_pubsub_topic.verify_email_topic.name
  role  = var.pubsub_iam_role

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_storage_bucket" "function_code_buckets" {
  name     = var.storage_bucket_name
  location = var.region
}

resource "google_storage_bucket_object" "function_code_objects" {
  name   = var.storage_bucket_object_name
  bucket = google_storage_bucket.function_code_buckets.name
  source = var.storage_bucket_object_source
}

resource "google_cloudfunctions2_function" "email_verification_function" {
  name        = var.cloud_function_name
  location    = var.region

  build_config {
    runtime     = var.cloud_function_run_time
    entry_point = var.cloud_function_entry_point
    source {
      storage_source {
        bucket = google_storage_bucket.function_code_buckets.name
        object = google_storage_bucket_object.function_code_objects.name
      }
    }
  }

  service_config {
    max_instance_count            = 1
    min_instance_count            = 0
    available_memory              = var.cloud_function_avalable_memory
    timeout_seconds               = 60
    vpc_connector                 = google_vpc_access_connector.connector.name
    vpc_connector_egress_settings = var.cloud_function_engress_setting

    environment_variables = {
      "MAILGUN_API_KEY"   = var.MAILGUN_API_KEY
      "DATABASE_USERNAME" = "${google_sql_user.users.name}"
      "DATABASE_PASSWORD" = "${google_sql_user.users.password}"
      "DATABASE_NAME"     = "${google_sql_database.cloud_computing_db.name}"
      "HOST"              = "${google_sql_database_instance.cloudsql_instance.ip_address.0.ip_address}"
    }

    ingress_settings               = var.cloud_function_ingress_setting
    all_traffic_on_latest_revision = true
    service_account_email          = google_service_account.service_account.email
  }
  event_trigger {
    trigger_region = var.region
    event_type     = var.cloud_function_event_type
    pubsub_topic   = google_pubsub_topic.verify_email_topic.id
    retry_policy   = var.cloud_function_role
  }
}

resource "google_project_iam_binding" "invoker_binding" {
  project = var.project_id
  role    = var.iam_binding_role
  members = ["serviceAccount:${google_service_account.service_account.email}"]
}

resource "google_vpc_access_connector" "connector" {
  name          = var.vpc_name
  region        = var.region
  ip_cidr_range = var.iam_ip_cidr_range
  network       = google_compute_network.cloudcomputing_vpc.name
}
