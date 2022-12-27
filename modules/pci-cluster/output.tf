# output "git_creds_public" {
#   value       = module.acm.git_creds_public
#   description = "Credentials to provide to git to enable config sync"
# }

output "ca_certificate" {
  value       = module.gke.ca_certificate
  description = "GKE context cert"
}

output "endpoint" {
  value       = module.gke.endpoint
  description = "GKE cluster endpoint"
}

