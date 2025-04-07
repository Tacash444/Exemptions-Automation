# locals {
  # files_path = "${var.factories_config.data_dir}/default-apis"
  # dns_files = {
  #   for workload_key, workload_value in module.workload-net-project : workload_key => flatten(
  #     [for default_file in fileset(local.files_path, "*.yaml") :
  #   "${local.files_path}/${default_file}"])
  # }
  # yaml_data = {
  #   for workload_key, workload_value in module.workload-net-project : workload_key => flatten([
  #     for file in local.dns_files[workload_key] : yamldecode(
  #       file("${file}")
  #     )
  #   ])
#   }

  # dns_zone_data = {
  #   for yaml_file in flatten([
  #     for workload_key, yaml_files in local.yaml_data :
  #     [
  #       for yaml_file in yaml_files :
  #       {
  #         workload_key = workload_key
  #         name         = yaml_file.name
  #         domain       = yaml_file.domain
  #         recordsets   = yaml_file.recordsets
  #       }
  #     ]
  #   ]) : "${yaml_file.workload_key}-${yaml_file.name}" => yaml_file
  # }
# }

# module "default-private-zone" {
#   source     = "../modules/dns"
#   for_each   = local.dns_zone_data
#   name       = each.value.name
#   project_id = module.workload-vpc[each.value.workload_key].project_id
#   zone_config = {
#     domain = each.value.domain
#     private = {
#       client_networks = [module.workload-vpc[each.value.workload_key].self_link]
#     }
#   }

#   recordsets = each.value.recordsets
# }
