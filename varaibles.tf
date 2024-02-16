variable "region" {
  type        = string
  description = "Google Cloud region"
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
  default     = "cloudcomputing"
  description = "Name of the Google Cloud network"
}

variable "routing_mode" {
  type        = string
  default     = "REGIONAL"
  description = "Routing mode for the Google Cloud network"
}

variable "webapp_subnet_name" {
  type        = string
  default     = "webapp"
  description = "Name of the webapp subnet"
}

variable "webapp_subnet_cidr" {
  type        = string
  default     = "10.0.1.0/24"
  description = "CIDR range for the webapp subnet"
}

variable "db_subnet_name" {
  type        = string
  default     = "db"
  description = "Name of the db subnet"
}

variable "db_subnet_cidr" {
  type        = string
  default     = "10.0.2.0/24"
  description = "CIDR range for the db subnet"
}
