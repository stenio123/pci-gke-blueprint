variable "project_id" {
  type        = string
  description = "Project ID for in-scope cluster"
}

variable "region" {
  type        = string
  description = "Region for cluster"
  default     = "us-central1"
}

variable "network" {
  type        = string
  description = "VPC name"
}

variable "subnet" {
  type        = string
  description = "Subnet name"
}

variable "mci" {
  type        = bool
  description = "Enable Multi Cluster Ingress on the config cluster"
  default     = false
}

variable "prefix" {
  type        = string
  description = "Name of cluster and prefix of other resources"
}

variable "master_ipv4_cidr_block" {
  type        = string
  description = "Control Plane CIDR for GKE cluster"
}

variable "enable_mesh_feature" {
  type        = bool
  description = "Enable ASM via this cluster. Should only be enabled on 1 cluster per fleet"
  default     = true
}

variable "enable_fleet_feature" {
  type        = bool
  description = "Enable ACM via this cluster. Should only be enabled on 1 cluster per fleet"
  default     = true
}

variable "module_depends_on" {
  description = "List of modules or resources this module depends on."
  type        = list(any)
  default     = []
}
