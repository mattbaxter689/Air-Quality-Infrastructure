variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "The region to deploy resources"
  type        = string
  default     = "northamerica-northeast1"
}

variable "zone" {
  description = "The zone to deploy the VM in"
  type        = string
  default     = "northamerica-northeast1-b"
}

variable "user_email" {
  description = "The user email used to grant IAM roles"
  type        = string
}


variable "image" {
  description = "OS Image for SSH"
  type        = string
  default     = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
}

variable "user_ip" {
  description = "The IP of the host machine"
  type        = string
}

variable "machine_type" {
  description = "The VM type to be used"
  type        = string
  default     = "e2-standard-2"
}

variable "vm_name" {
  description = "The name to be given to the VM"
  type        = string
}

variable "service_account" {
  description = "The name of the service account for github actions"
  type        = string
}
