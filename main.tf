provider "google" {
  credentials = file(var.GOOGLE_CREDENTIALS)
  project     = var.project_id
  region      = var.region
}

resource "google_service_account" "service_account" {
  account_id   = var.service_account_account_id
  display_name = var.service_account_display_name
}

resource "google_service_account" "function_service_account" {
  account_id   = var.cloudfunction_account_id
  display_name = var.cloudfunction_display_name
}

# Create a Key Ring
resource "google_kms_key_ring" "key_ring" {
  name     = "kms-key-rings-three"
  location = var.region
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

resource "google_kms_crypto_key" "cloudsql_crypto_key" {
  name     = "cloudsql-crypto-key"
  key_ring = google_kms_key_ring.key_ring.id
  rotation_period = "2592000s" # 30 days
}

resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  project  = var.project_id
  service  = "sqladmin.googleapis.com"
}

resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  provider      = google-beta
  crypto_key_id = google_kms_crypto_key.cloudsql_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}",
  ]
}

resource "google_sql_database_instance" "cloudsql_instance" {
  name                = "db-instance-${random_id.db_name_suffix.hex}"
  database_version    = var.cloudsql_database_version
  project             = var.project_id
  region              = var.region
  deletion_protection = var.deletion_protection
  depends_on          = [google_service_networking_connection.default]
  encryption_key_name = google_kms_crypto_key.cloudsql_crypto_key.id
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

# resource "google_compute_instance" "vm_CloudComputing" {
#   name         = var.vm_name
#   machine_type = var.vm_machine_type
#   zone         = var.zone
#   boot_disk {
#     initialize_params {
#       image = var.vm_disk_image
#       size  = 100
#       type  = var.vm_disk_type
#     }
#   }
#   network_interface {
#     subnetwork = google_compute_subnetwork.webapp_subnet.self_link
#     access_config {}
#   }

#   service_account {
#     email  = google_service_account.service_account.email
#     scopes = [var.service_account_scope, var.service_account_scope_role]
#   }

#   metadata_startup_script = <<-EOT
#   #!/bin/bash

#   set -e
#   echo "Hello World!"


#   env_file="/home/webapp/.env"

#   echo "DATABASE_NAME=${google_sql_database.cloud_computing_db.name}" >> "$env_file"
#   echo "HOST=${google_sql_database_instance.cloudsql_instance.ip_address.0.ip_address}" >> "$env_file"
#   echo "DATABASE_USERNAME=${google_sql_user.users.name}" >> "$env_file"
#   echo "DATABASE_PASSWORD=${google_sql_user.users.password}" >> "$env_file"
#   echo "PORT=3306" >> "$env_file"
#   EOT
# }

data "google_dns_managed_zone" "existing_zone" {
  name = var.existing_zone_name
}

resource "google_dns_record_set" "dns_record" {
  name         = var.dns_record_name
  type         = var.dns_record_type
  ttl          = 300
  managed_zone = data.google_dns_managed_zone.existing_zone.name
  rrdatas      = [google_compute_global_address.lb_ipv4_address.address]
}

resource "google_kms_crypto_key" "vm_crypto_key" {
  name     = "vm-crypto-key"
  key_ring = google_kms_key_ring.key_ring.id
  rotation_period = "2592000s" # 30 days
}

resource "google_kms_crypto_key_iam_binding" "vm_crypto_key" {
  provider      = google-beta
  crypto_key_id = google_kms_crypto_key.vm_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = ["serviceAccount:service-296000346479@compute-system.iam.gserviceaccount.com"]
}

resource "google_compute_region_instance_template" "webapp_template" {
  name_prefix  = var.instance_template_name
  machine_type = var.vm_machine_type
  tags         = [var.instance_template_tags]
  region       = var.region
  

  disk {
    source_image = var.vm_disk_image
    auto_delete  = var.auto_delete
    boot         = var.boot
    disk_size_gb = var.disk_size_gb
    disk_type    = var.vm_disk_type
    disk_encryption_key {
      kms_key_self_link = google_kms_crypto_key.vm_crypto_key.id
    }
  }

  network_interface {
    network    = google_compute_network.cloudcomputing_vpc.id
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

resource "google_compute_http_health_check" "webapp_health_check" {
  name                = var.health_check_name
  check_interval_sec  = var.check_interval_sec
  timeout_sec         = var.timeout_sec
  healthy_threshold   = var.healthy_threshold
  unhealthy_threshold = var.unhealthy_threshold
  port                = var.port
  request_path        = var.health_request_path
}

resource "google_compute_region_instance_group_manager" "webapp_igm" {
  name               = var.instance_group_manager_name
  region             = var.region
  base_instance_name = var.base_instance_name

  version {
    instance_template = google_compute_region_instance_template.webapp_template.self_link
    name              = var.version_name
  }

  named_port {
    name = var.named_port_name
    port = var.port
  }

  auto_healing_policies {
    health_check      = google_compute_http_health_check.webapp_health_check.self_link
    initial_delay_sec = var.initial_delay_sec
  }

  target_size = var.target_size
}

resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  name   = var.auto_scaler_name
  region = var.region
  target = google_compute_region_instance_group_manager.webapp_igm.self_link

  autoscaling_policy {
    max_replicas    = var.max_replicas
    min_replicas    = var.min_replicas
    cooldown_period = var.cooldown_period

    cpu_utilization {
      target = var.target_cpu_utilization
    }
  }
}

# Load Balancer
resource "google_compute_global_address" "lb_ipv4_address" {
  name = var.global_address2_name
}

resource "google_compute_global_forwarding_rule" "https_forwarding_rule" {
  name                  = var.forwarding_rule_name
  ip_protocol           = var.ip_protocol
  load_balancing_scheme = var.load_balancing_scheme
  ip_address            = google_compute_global_address.lb_ipv4_address.address
  port_range            = var.port_range
  target                = google_compute_target_https_proxy.https_proxy.self_link
}

resource "google_compute_target_https_proxy" "https_proxy" {
  name             = var.https_proxy_name
  url_map          = google_compute_url_map.https_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.webapp_ssl_cert.self_link]
  depends_on       = [google_compute_managed_ssl_certificate.webapp_ssl_cert]
}

resource "google_compute_url_map" "https_url_map" {
  name            = var.https_url_map_name
  default_service = google_compute_backend_service.webapp_backend.self_link
}

resource "google_compute_managed_ssl_certificate" "webapp_ssl_cert" {
  name = var.ssl_certificate_name

  managed {
    domains = [var.dns_record_name]
  }
}

resource "google_compute_backend_service" "webapp_backend" {
  name                            = var.backend_service_name
  protocol                        = var.backend_protocol
  port_name                       = var.backend_port_name
  health_checks                   = [google_compute_http_health_check.webapp_health_check.self_link]
  load_balancing_scheme           = var.backend_load_balancing_scheme
  timeout_sec                     = var.backend_timeout_sec
  enable_cdn                      = var.backend_enable_cdn
  connection_draining_timeout_sec = var.backend_connection_draining_timeout_sec


  backend {
    group           = google_compute_region_instance_group_manager.webapp_igm.instance_group
    balancing_mode  = var.backend_balancing_mode
    capacity_scaler = var.backend_capacity_scaler
  }
}

# Firewall Rule
resource "google_compute_firewall" "allow_lb" {
  name    = var.firewall_rule_name_custom
  network = google_compute_network.cloudcomputing_vpc.name

  allow {
    protocol = var.firewall_protocol_custom
    ports    = var.firewall_ports_custom
  }

  source_ranges = var.firewall_source_ranges_custom
  target_tags   = var.firewall_target_tags_custom
}

resource "google_project_iam_binding" "instance_admin_binding" {
  project = var.project_id
  role    = var.iam_role

  members = [
    "serviceAccount:${google_service_account.service_account.email}",
  ]
}

resource "google_service_account" "vm_service_account" {
  account_id   = var.service_account_account_id_custom
  display_name = var.service_account_display_name_custom
}


resource "google_compute_firewall" "default" {
  name          = var.unique_firewall_rule_name_custom
  provider      = google
  direction     = var.unique_firewall_direction_custom
  network       = google_compute_network.cloudcomputing_vpc.id
  source_ranges = var.unique_firewall_source_ranges_custom
  allow {
    protocol = var.unique_firewall_protocol_custom
  }
  target_tags = var.unique_firewall_target_tags_custom
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

resource "google_project_iam_binding" "function_service_account_roles" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${google_service_account.function_service_account.email}"
  ]
}

resource "google_project_iam_binding" "pubsub_service_account_roles" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

# Create a CMEK for Cloud Storage Buckets
resource "google_kms_crypto_key" "storage_crypto_key" {
  name            = "storage-crypto-key"
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = "2592000s" # 30 days
}

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_kms_crypto_key_iam_binding" "binding" {
  crypto_key_id = google_kms_crypto_key.storage_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"
    ]
}

resource "google_storage_bucket" "function_code_buckets" {
  name     = var.storage_bucket_name
  location = var.region
  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_crypto_key.id
  }
}

resource "google_storage_bucket_object" "function_code_objects" {
  name   = var.storage_bucket_object_name
  bucket = google_storage_bucket.function_code_buckets.name
  source = var.storage_bucket_object_source
}

resource "google_cloudfunctions2_function" "email_verification_function" {
  name     = var.cloud_function_name
  location = var.region

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
    service_account_email          = google_service_account.function_service_account.email
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
