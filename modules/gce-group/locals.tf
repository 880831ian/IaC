locals {
  network_project_id = var.network_project_id != "" ? var.network_project_id : var.project_id
  full_instance_paths = [for instance in var.instances : format("https://www.googleapis.com/compute/v1/projects/%s/zones/%s/instances/%s", var.project_id, var.zone, instance)]  
}