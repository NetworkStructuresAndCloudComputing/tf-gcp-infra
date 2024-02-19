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

variable "vm_network"{
  type = string
  description = "network of virual machnine"
}

variable "route_dest_range"{
  type = string
  description = "destination range of vpc route"
}

variable "route_next_hop_gateway"{
  type = string
  description = "next to hop gateway route"
}

variable "default_route_name"{
  type = string
  description = "name of the default rate"
}

variable "firewall_source_ranges"{
  type = string
  description = "source ranges"
}

variable "firewall_ports"{
  type = string
  description = "ports for the firewall"
}

variable "firewall_protocol"{
  type = string
  description = "protocol for the firewall"
}