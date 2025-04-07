locals {
  subunits_environments = merge([
    for env in var.environments :
    {
      for key, value in local.subunits :
      "${key}-${env}" => value
    }
  ]...)
}


module "subunits-folder" {
  source   = "../modules/folder"
  for_each = local.subunits
  parent   = module.units-folder[each.value.unit_key].id
  name     = each.value.descriptive_name
  iam = {
    "roles/iap.tunnelResourceAccessor"   = ["group:${each.value.admin_group}"]
    "roles/logging.admin"                = ["group:${each.value.admin_group}"]
    "roles/monitoring.admin"             = ["group:${each.value.admin_group}"]
    "roles/viewer"                       = ["group:${each.value.admin_group}"]
    "roles/resourcemanager.folderViewer" = ["group:${each.value.admin_group}"]
  }
  tag_bindings = {
    subunit = module.organization-tags.tag_values["subunit/${each.key}"].id
  }
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/${each.value.division_key}/${each.value.unit_key}/${each.key}"
  }
}

module "subunits-env-folder" {
  source   = "../modules/folder"
  for_each = local.subunits_environments
  parent   = module.subunits-folder[split("-", each.key)[0]].id
  name     = title(split("-", each.key)[1])

  iam = {
    "roles/resourcemanager.projectCreator" = try([module.pf-sas["${split("-", each.key)[0]}-${substr(split("-", each.key)[1], 0, 3)}"].iam_email], [])
    "roles/resourcemanager.projectDeleter" = try([module.pf-sas["${split("-", each.key)[0]}-${substr(split("-", each.key)[1], 0, 3)}"].iam_email], [])
    "roles/resourcemanager.folderAdmin"    = try([module.pf-sas["${split("-", each.key)[0]}-${substr(split("-", each.key)[1], 0, 3)}"].iam_email], [])
    "roles/owner"                          = try([module.pf-sas["${split("-", each.key)[0]}-${substr(split("-", each.key)[1], 0, 3)}"].iam_email], [])
    "roles/compute.xpnAdmin"               = try([module.pf-sas["${split("-", each.key)[0]}-${substr(split("-", each.key)[1], 0, 3)}"].iam_email], [])
    "roles/storage.admin"                  = try([module.pf-sas["${split("-", each.key)[0]}-${substr(split("-", each.key)[1], 0, 3)}"].iam_email], [])
  }
  tag_bindings = {
    environment = module.organization-tags.tag_values["environment/${split("-", each.key)[1]}"].id
  }

  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/${each.value.division_key}/${each.value.unit_key}/${replace(each.key, "-", "/")}"
  }
}

# only for 
module "subunits-int-shared-services-folder" {
  source   = "../modules/folder"
  for_each = local.subunits
  parent   = module.subunits-env-folder["${each.key}-integration"].id
  name     = "Shared Services"
  iam = {
    for key, value in toset(local._network_folder_iam) : value => [module.branch-env-network-sa["integration"].iam_email]
  }
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/${each.value.division_key}/${each.value.unit_key}/${replace(each.key, "-", "/")}/shared"
  }
}