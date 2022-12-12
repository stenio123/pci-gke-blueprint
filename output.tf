# output "git_creds_public" {
#   value       = { "in-scope" = module.in_scope_cluster.git_creds_public, "out-of-scope" = module.out_of_scope_cluster.git_creds_public }
#   description = "Credentials to provide to git to enable config sync"
# }