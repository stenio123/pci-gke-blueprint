


module "gke" {
  source                          = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"
  project_id                      = var.project_id
  name                            = var.prefix
  regional                        = true
  region                          = var.region
  network                         = var.network
  subnetwork                      = var.subnet
  release_channel                 = "REGULAR"
  ip_range_pods                   = "${var.prefix}-pods"
  ip_range_services               = "${var.prefix}-services"
  create_service_account          = true
  horizontal_pod_autoscaling      = true
  enable_vertical_pod_autoscaling = true
  enable_private_endpoint         = false
  enable_private_nodes            = true
  master_ipv4_cidr_block          = var.master_ipv4_cidr_block
  cluster_resource_labels         = { "mesh_id" : "proj-${data.google_project.project.number}" }
  identity_namespace              = "${var.project_id}.svc.id.goog"

  add_cluster_firewall_rules        = true
  add_master_webhook_firewall_rules = true

  master_authorized_networks = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "all"
    }
  ]

}

module "hub" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/fleet-membership"

  project_id      = var.project_id
  cluster_name    = module.gke.name
  location        = var.region
  membership_name = "${module.gke.name}-fleet-membership"
}

resource "kubernetes_namespace" "config_management_system" {
  metadata {
    name = "config-management-system"
  }
}

# module "acm" {
#   source = "terraform-google-modules/kubernetes-engine/google//modules/acm"

#   project_id   = var.project_id
#   location     = module.gke.location
#   cluster_name = module.gke.name
  
#   cluster_membership_id = module.hub.cluster_membership_id

#   sync_repo   = "git@github.com:gtsorbo/pci-acm-test.git"
#   sync_branch = "main"
#   policy_dir  = var.prefix

#   secret_type = "ssh"

#   enable_fleet_feature      = var.enable_fleet_feature
#   enable_fleet_registration = false

#   depends_on = [
#     module.hub,
#     kubernetes_namespace.config_management_system,
#     var.module_depends_on
#   ]
# }

module "asm" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/asm"

  project_id                = var.project_id
  cluster_name              = module.gke.name
  cluster_location          = module.gke.location
  internal_ip               = false
  multicluster_mode         = "connected"
  enable_cni                = true
  enable_mesh_feature       = var.enable_mesh_feature
  enable_fleet_registration = false

  module_depends_on = concat([module.hub], var.module_depends_on)
}

resource "google_gke_hub_feature" "mci" {
  count    = var.mci == true ? 1 : 0
  name     = "multiclusteringress"
  project  = var.project_id
  location = "global"
  spec {
    multiclusteringress {
      config_membership = "projects/${var.project_id}/locations/global/memberships/${module.hub.cluster_membership_id}"
    }
  }
  provider = google-beta
}

data "google_project" "project" {
  project_id = var.project_id
}