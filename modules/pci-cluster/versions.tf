terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 3.45"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">= 3.45"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
    }
  }
}