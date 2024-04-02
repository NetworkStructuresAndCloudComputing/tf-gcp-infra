variable "region" {
  type        = string
  description = "Google Cloud region"
}

variable "zone" {
  type        = string
  description = "Google Cloud zone"
}

variable "project_id" {
  type        = string
  description = "Google Cloud project ID"
}

variable "GOOGLE_CREDENTIALS" {
  type        = string
  description = "Google Cloud JSON"
}

variable "network_name" {
  type        = string
  description = "Name of the Google Cloud network"
}

variable "routing_mode" {
  type        = string
  description = "Routing mode for the Google Cloud network"
}

variable "webapp_subnet_name" {
  type        = string
  description = "Name of the webapp subnet"
}
variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "vm_firewall" {
  type        = string
  default     = "firewallofcloudcomputing"
  description = "Name of the firewall"
}

variable "vm_firewall_two" {
  type        = string
  default     = "firewallofcloudcomputingsecondone"
  description = "Name of the firewall"
}

variable "webapp_subnet_cidr" {
  type        = string
  description = "CIDR range for the webapp subnet"
}

variable "db_subnet_name" {
  type        = string
  description = "Name of the db subnet"
}

variable "db_subnet_cidr" {
  type        = string
  description = "CIDR range for the db subnet"
}

variable "vm_disk_image" {
  type        = string
  description = "virtual machine disk image"
}

variable "vm_disk_type" {
  type        = string
  description = "virtual machine disk type"
}

variable "vm_machine_type" {
  type        = string
  description = "machine type of virual machine"
}

variable "vm_network" {
  type        = string
  description = "network of virual machnine"
}

variable "route_dest_range" {
  type        = string
  description = "destination range of vpc route"
}

variable "route_next_hop_gateway" {
  type        = string
  description = "next to hop gateway route"
}

variable "default_route_name" {
  type        = string
  description = "name of the default rate"
}

variable "firewall_source_ranges" {
  type        = string
  description = "source ranges"
}

variable "firewall_ports" {
  type        = string
  description = "ports for the firewall"
}

variable "firewall_protocol" {
  type        = string
  description = "protocol for the firewall"
}

variable "cloudsql_instance_name" {
  description = "Name of the CloudSQL instance"
  type        = string
}

variable "cloudsql_database_version" {
  description = "Database version for CloudSQL instance"
  type        = string
}

variable "deletion_protection" {
  description = "Enable deletion protection for CloudSQL instance"
  type        = bool
}

variable "availability_type" {
  description = "CloudSQL instance availability type"
  type        = string
}

variable "cloudsql_disk_type" {
  description = "CloudSQL instance disk type"
  type        = string
}

variable "cloudsql_disk_size" {
  description = "CloudSQL instance disk size"
  type        = string
}

variable "cloudsql_ipv4_enabled" {
  description = "CloudSQL instance ipv4"
  type        = bool
}

variable "cloudsql_tier" {
  description = "CloudSQL instance tier"
  type        = string
}

variable "cloudsql_database" {
  description = "CloudSQL database"
  type        = string
}

variable "sql_name" {
  description = "SQL name"
  type        = string
}

variable "global_address_name" {
  description = "global address name"
  type        = string
}

variable "global_address_type" {
  description = "global address type"
  type        = string
}

variable "global_address_purpose" {
  description = "global address purpose"
  type        = string
}

variable "deletion_policy" {
  description = "deletion policy"
  type        = string
}

variable "network_service" {
  description = "network service"
  type        = string
}

variable "prefix_length" {
  description = "prefix length"
  type        = string
}

variable "address_type" {
  description = "address type"
  type        = string
}

variable "domain_name" {
  description = "domain name"
  type        = string
}

variable "zone_name" {
  description = "zone name"
  type        = string
}

variable "iam_service" {
  description = "service name"
  type        = string
}

variable "service_account_account_id" {
  description = "account id"
  type        = string
}

variable "service_account_display_name" {
  description = "display name"
  type        = string
}

variable "cloudfunction_account_id" {
  description = "account id"
  type        = string
}

variable "cloudfunction_display_name" {
  description = "display name"
  type        = string
}


variable "logging_admin_role" {
  description = "logging admin role"
  type        = string
}

variable "monitoring_metric_writern_role" {
  description = "monitoring metric writer"
  type        = string
}

variable "logging_writer_role" {
  description = "logging writer"
  type        = string
}

variable "service_account_scope" {
  description = "service account scope"
  type        = string
}

variable "service_account_scope_role" {
  description = "service account scope role"
  type        = string
}

variable "existing_zone_name" {
  description = "existing zone name"
  type        = string
}

variable "dns_record_name" {
  description = "dns record name"
  type        = string
}

variable "dns_record_type" {
  description = "dns record type"
  type        = string
}

variable "dns_record_name_spf" {
  description = "dns record name SPF"
  type        = string
}

variable "dns_record_type_spf" {
  description = "dns record type SPF"
  type        = string
}

variable "dns_record_name_dkim" {
  description = "dns record name DKIM"
  type        = string
}

variable "dns_record_type_dkim" {
  description = "dns record type DKIM"
  type        = string
}

variable "dns_record_name_mx" {
  description = "dns record name DKIM"
  type        = string
}

variable "dns_record_type_mx" {
  description = "dns record type DKIM"
  type        = string
}

variable "dns_record_name_cname" {
  description = "dns record name DKIM"
  type        = string
}

variable "dns_record_type_cname" {
  description = "dns record type DKIM"
  type        = string
}

variable "MAILGUN_API_KEY" {
  description = "mail gun key"
  type        = string
}

variable "cname_rrdata" {
  description = "rrdata"
  type        = string
}

variable "pubsub_topic_name" {
  description = "name of pubsun topic"
  type        = string
}

variable "retentation_duration" {
  description = "retentation duration"
  type        = string
}

variable "pubsub_subscription_name" {
  description = "pubsub subscription name"
  type        = string
}

variable "expiration_policy" {
  description = "expiration policy"
  type        = string
}

variable "pubsub_iam_role" {
  description = "pubsub iam role"
  type        = string
}

variable "storage_bucket_name" {
  description = "storage bucket name"
  type        = string
}

variable "storage_bucket_object_name" {
  description = "storage bucket object name"
  type        = string
}

variable "storage_bucket_object_source" {
  description = "storage bucket object source"
  type        = string
}

variable "cloud_function_name" {
  description = "cloud function name"
  type        = string
}

variable "cloud_function_run_time" {
  description = "cloud function run time"
  type        = string
}

variable "cloud_function_entry_point" {
  description = "cloud function entry point"
  type        = string
}

variable "cloud_function_avalable_memory" {
  description = "cloud function avalable memory"
  type        = string
}

variable "cloud_function_engress_setting" {
  description = "cloud function engress setting"
  type        = string
}

variable "cloud_function_ingress_setting" {
  description = "cloud function ingress setting"
  type        = string
}

variable "cloud_function_event_type" {
  description = "cloud function event type"
  type        = string
}

variable "cloud_function_role" {
  description = "cloud function role"
  type        = string
}

variable "iam_binding_role" {
  description = "iam binding role"
  type        = string
}

variable "vpc_name" {
  description = "vpc name"
  type        = string
}

variable "iam_ip_cidr_range" {
  description = "iam ip cidr range"
  type        = string
}