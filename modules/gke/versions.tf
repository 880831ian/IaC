terraform {
  required_version = ">=1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.5.0, < 6"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
  }
  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-kubernetes-engine:private-cluster-update-variant/v29.0.0"
  }
}
