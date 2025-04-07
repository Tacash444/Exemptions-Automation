locals {
  host_project_ids = merge(
    {
      for key, value in module.subunit-net-project : split("-", key)[0] => value.id
    },
  )
  host_project_numbers = merge(
    {
      for key, value in module.subunit-net-project : key => value.number
    },
  )

  tfvars = {
    host_project_ids        = local.host_project_ids
    integration_host_project_numbers    = local.host_project_numbers
    vpc_self_links          = local.vpc_self_links
  }
  vpc_self_links = merge(
    {
      for key, value in module.subunit-vpc : split("-", key)[0] => value.self_link
    },
  )
}

# generate tfvars file for subsequent stages

resource "local_file" "tfvars" {
  for_each        = var.outputs_location == null ? {} : { 1 = 1 }
  file_permission = "0644"
  filename        = "${try(pathexpand(var.outputs_location), "")}/tfvars/2-networking-integration.auto.tfvars.json"
  content         = jsonencode(local.tfvars)
}

# outputs

output "host_project_ids" {
  description = "Network project ids."
  value       = local.host_project_ids
}

output "host_project_numbers" {
  description = "Network project numbers."
  value       = local.host_project_numbers
}

output "shared_vpc_self_links" {
  description = "Shared VPC self links."
  value       = local.vpc_self_links
}

output "tfvars" {
  description = "Terraform variables file for the following stages."
  sensitive   = true
  value       = local.tfvars
}
