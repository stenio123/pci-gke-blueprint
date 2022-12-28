module "project" {
  source  = "terraform-google-modules/project-factory/google"
  version = "~> 14.0"

  name              = "pci-refresh-test"
  random_project_id = true
  org_id            = var.org_id
  folder_id         = var.folder_id
  billing_account   = var.billing_account

  default_service_account = "keep"

  activate_apis = [
    "anthosconfigmanagement.googleapis.com",
    "cloudtrace.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "dns.googleapis.com",
    "gkehub.googleapis.com",
    "meshconfig.googleapis.com",
    "mesh.googleapis.com",
    "multiclusteringress.googleapis.com",
    "multiclusterservicediscovery.googleapis.com",
    "trafficdirector.googleapis.com"
  ]
}

locals {
  project_id          = module.project.project_id
  in_scope_prefix     = "in-scope"
  out_of_scope_prefix = "out-of-scope"
  region              = "us-central1"

  domain = var.domain

  google_compute_security_policy_sqli_rule_expression_list = <<EOT
    evaluatePreconfiguredExpr('sqli-stable',[
      'owasp-crs-v030001-id942110-sqli',
      'owasp-crs-v030001-id942120-sqli',
      'owasp-crs-v030001-id942150-sqli',
      'owasp-crs-v030001-id942180-sqli',
      'owasp-crs-v030001-id942200-sqli',
      'owasp-crs-v030001-id942210-sqli',
      'owasp-crs-v030001-id942260-sqli',
      'owasp-crs-v030001-id942300-sqli',
      'owasp-crs-v030001-id942310-sqli',
      'owasp-crs-v030001-id942330-sqli',
      'owasp-crs-v030001-id942340-sqli',
      'owasp-crs-v030001-id942380-sqli',
      'owasp-crs-v030001-id942390-sqli',
      'owasp-crs-v030001-id942400-sqli',
      'owasp-crs-v030001-id942410-sqli',
      'owasp-crs-v030001-id942430-sqli',
      'owasp-crs-v030001-id942440-sqli',
      'owasp-crs-v030001-id942450-sqli',
      'owasp-crs-v030001-id942251-sqli',
      'owasp-crs-v030001-id942420-sqli',
      'owasp-crs-v030001-id942431-sqli',
      'owasp-crs-v030001-id942460-sqli',
      'owasp-crs-v030001-id942421-sqli',
      'owasp-crs-v030001-id942432-sqli'
    ])
EOT

    # in_scope_manifests = [
    #     "kubernetes-manifests/deployments/checkoutservice.yaml",
    #     "kubernetes-manifests/deployments/paymentservice.yaml",
    #     "kubernetes-manifests/deployments/frontend.yaml",
    #     "kubernetes-manifests/namespaces/checkout.yaml",
    #     "kubernetes-manifests/namespaces/frontend.yaml",
    #     "kubernetes-manifests/namespaces/payment.yaml",
    #     "kubernetes-manifests/services/checkoutservice.yaml",
    #     "kubernetes-manifests/services/paymentservice.yaml",
    #     "kubernetes-manifests/services/frontend.yaml",
    #     "kubernetes-manifests/services/out-of-scope-services.yaml",
    # ]

    # out_of_scope_manifests = [
    #     "kubernetes-manifests/deployments/shippingservice.yaml",
    #     "kubernetes-manifests/deployments/adservice.yaml",
    #     "kubernetes-manifests/deployments/emailservice.yaml",
    #     "kubernetes-manifests/deployments/currencyservice.yaml",
    #     "kubernetes-manifests/deployments/cartservice.yaml",
    #     "kubernetes-manifests/deployments/recommendationservice.yaml",
    #     "kubernetes-manifests/deployments/productcatalogservice.yaml",
    #     "kubernetes-manifests/namespaces/ad.yaml",
    #     "kubernetes-manifests/namespaces/cart.yaml",
    #     "kubernetes-manifests/namespaces/shipping.yaml",
    #     "kubernetes-manifests/namespaces/email.yaml",
    #     "kubernetes-manifests/namespaces/currency.yaml",
    #     "kubernetes-manifests/namespaces/product-catalog.yaml",
    #     "kubernetes-manifests/namespaces/recommendation.yaml",
    #     "kubernetes-manifests/services/shippingservice.yaml",
    #     "kubernetes-manifests/services/adservice.yaml",
    #     "kubernetes-manifests/services/emailservice.yaml",
    #     "kubernetes-manifests/services/currencyservice.yaml",
    #     "kubernetes-manifests/services/cartservice.yaml",
    #     "kubernetes-manifests/services/recommendationservice.yaml",
    #     "kubernetes-manifests/services/productcatalogservice.yaml",
    # ]
}

# google_client_config and kubernetes provider must be explicitly specified like the following.
# source: https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google/latest/submodules/beta-autopilot-private-cluster
data "google_client_config" "default" {}

provider "kubernetes" {
  alias                  = "in-scope"
  host                   = "https://${module.in_scope_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.in_scope_cluster.ca_certificate)
}

provider "kubernetes" {
  alias                  = "out-of-scope"
  host                   = "https://${module.out_of_scope_cluster.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.out_of_scope_cluster.ca_certificate)
}

# resource "google_gke_hub_feature" "acm" {
#   provider = google-beta

#   name     = "configmanagement"
#   project  = local.project_id
#   location = "global"
# }

# resource "google_gke_hub_feature" "mesh" {
#   name     = "servicemesh"
#   project  = local.project_id
#   location = "global"
#   provider = google-beta
# }

resource "google_gke_hub_feature" "mcsd" {
  name     = "multiclusterservicediscovery"
  location = "global"
  project  = local.project_id

  provider = google-beta
}

module "in_scope_cluster" {
  source = "./modules/pci-cluster"

  prefix                 = local.in_scope_prefix
  project_id             = local.project_id
  mci                    = true
  network                = module.vpc.network_name
  subnet                 = module.vpc.subnets_names[0]
  region                 = local.region
  master_ipv4_cidr_block = "10.10.11.0/28"

 /** providers = {
    kubernetes = kubernetes.in-scope
  }*/
}

module "out_of_scope_cluster" {
  source = "./modules/pci-cluster"

  prefix                 = local.out_of_scope_prefix
  project_id             = local.project_id
  network                = module.vpc.network_name
  subnet                 = module.vpc.subnets_names[1]
  region                 = local.region
  master_ipv4_cidr_block = "10.10.12.0/28"
  mci                    = false
  enable_mesh_feature    = false
  enable_fleet_feature   = false

 /** providers = {
    kubernetes = kubernetes.out-of-scope
  }*/

  module_depends_on = [module.in_scope_cluster]
}

module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 4.0"

  project_id   = local.project_id
  network_name = "pci-vpc"
  routing_mode = "GLOBAL"

  subnets = [
    {
      subnet_name           = "${local.in_scope_prefix}-subnet"
      subnet_ip             = "10.0.4.0/22"
      subnet_private_access = true
      subnet_region         = local.region
    },
    {
      subnet_name           = "${local.out_of_scope_prefix}-subnet"
      subnet_ip             = "172.16.4.0/22"
      subnet_private_access = true
      subnet_region         = local.region
    }
  ]

  secondary_ranges = {
    "${local.in_scope_prefix}-subnet" = [
      {
        range_name    = "${local.in_scope_prefix}-pods"
        ip_cidr_range = "10.4.0.0/14"
      },
      {
        range_name    = "${local.in_scope_prefix}-services"
        ip_cidr_range = "10.0.32.0/20"
      }
    ]

    "${local.out_of_scope_prefix}-subnet" = [
      {
        range_name    = "${local.out_of_scope_prefix}-pods"
        ip_cidr_range = "172.20.0.0/14"
      },
      {
        range_name    = "${local.out_of_scope_prefix}-services"
        ip_cidr_range = "172.16.16.0/20"
      }
    ]
  }
}

module "cloud_router" {
  source  = "terraform-google-modules/cloud-router/google"
  version = "~> 0.4"
  project = local.project_id
  name    = "router"
  network = module.vpc.network_name
  region  = local.region

  nats = [{
    name = "nat-all"
  }]
}

# resource "google_compute_managed_ssl_certificate" "frontend" {
#   name = "frontend"
#   project = local.project_id

#   managed {
#     domains = [local.domain]
#   }
# }
/**
resource "kubernetes_manifest" "frontend_ingress" {
    provider = kubernetes.in-scope
    manifest = yamldecode(<<EOT
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend
  namespace: frontend
  annotations:
    # frontend-ext-ip is the name of the IP address resource created in terraform as
    # google_compute_global_address.frontend-ext-ip
    kubernetes.io/ingress.global-static-ip-name: ${google_compute_global_address.in_scope_ingress.name}
    kubernetes.io/ingress.allow-http: "false"
    kubernetes.io/ingress.class: "gce"
    # networking.gke.io/managed-certificates: frontend
spec:
  rules:
  - http:
      paths:
        - path: "/*"
          pathType: ImplementationSpecific
          backend:
            service:
              name: frontend
              port: 
                number: 80
EOT
)
}

resource "kubernetes_manifest" "managed_cert" {
    provider = kubernetes.in-scope
    manifest = yamldecode(<<EOT
apiVersion: networking.gke.io/v1beta1
kind: ManagedCertificate
metadata:
  name: frontend
  namespace: frontend
spec:
  domains:
    - ${replace(google_compute_global_address.in_scope_ingress.address, ".", "-")}.nip.io
EOT
)
}

resource "kubernetes_manifest" "backend_config" {
    provider = kubernetes.in-scope
    manifest = yamldecode(<<EOT
apiVersion: cloud.google.com/v1beta1
kind: BackendConfig
metadata:
  name: security-policy-mapping
  namespace: frontend
spec:
  securityPolicy:
    name: "${google_compute_security_policy.security-policy-1.name}"
EOT
)
}*/

resource "google_dns_managed_zone" "frontend" {
  project    = local.project_id
  name       = "frontend-zone"
  dns_name   = local.domain
}

resource "google_dns_record_set" "frontend" {
  project      = local.project_id
  name         = "store.${google_dns_managed_zone.frontend.dns_name}"
  type         = "A"
  ttl          = 300
  managed_zone = google_dns_managed_zone.frontend.name
  rrdatas      = [google_compute_global_address.in_scope_ingress.address]
}

resource "google_compute_global_address" "in_scope_ingress" {
  name         = "frontend-ext-ip"
  project      = local.project_id
  description  = "in-scope-ingress"
  address_type = "EXTERNAL"
}

resource "google_compute_security_policy" "security-policy-1" {
  name        = "frontend-application-security-policy"
  project     = local.project_id
  description = "web application security policy"

  rule {
    action   = "deny(403)"
    priority = "1000"
    match {
      expr {
        expression = local.google_compute_security_policy_sqli_rule_expression_list
      }
    }
    description = "Cloud Armor tuned WAF rules for SQL injection"
  }

  rule {
    action   = "deny(403)"
    priority = "2000"
    match {
      expr {
        expression = "evaluatePreconfiguredExpr('xss-stable')"
      }
    }
    description = "Deny access to XSS attempts"
  }

  rule {
    action   = "allow"
    priority = "2147483647"
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default rule"
  }
}
