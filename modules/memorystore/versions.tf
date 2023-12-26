terraform {
  required_version = ">=1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.5.0, < 6"
    }
  }

  provider_meta "google" {
    module_name = "blueprints/terraform/terraform-google-memorystore/v7.1.3"
  }
}
