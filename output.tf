output "in_scope_ingress_name" {
  value       = google_compute_global_address.in_scope_ingress.name
  description = "GKE in-scope cluster ingress name"
}

# nip.io is a convenience, https://nip.io/ for more info
output "in_scope_ingress_address" {
  value       = "${replace(google_compute_global_address.in_scope_ingress.address, ".", "-")}.nip.io"
  description = "GKE in-scope cluster ingress address"
}

output "security_policy_name" {
  value       = google_compute_security_policy.security-policy-1.name
  description = "Security policy to be applied to GKE in-scope cluster"
}