variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "GCP region for resources."
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for VM instances."
  type        = string
  default     = "us-central1-a"
}

variable "api_machine_type" {
  description = "Machine type for the public API gateway VM."
  type        = string
  default     = "e2-medium"
}

variable "worker_machine_type" {
  description = "Machine type for the private worker VMs."
  type        = string
  default     = "e2-small"
}

variable "instance_image" {
  description = "Base image used for all Compute Engine VMs."
  type        = string
  default     = "debian-cloud/debian-12"
}

variable "repo_url" {
  description = "Optional repository URL to clone on instance startup. Leave empty to provision without cloning."
  type        = string
  default     = ""
}
