module "units-folder" {
  source   = "../modules/folder"
  for_each = local.units
  parent   = module.divisions-folder[each.value.division_key].id
  name     = each.value.descriptive_name
  iam = {
    "roles/iap.tunnelResourceAccessor"   = ["group:${each.value.admin_group}"]
    "roles/logging.admin"                = ["group:${each.value.admin_group}"]
    "roles/monitoring.admin"             = ["group:${each.value.admin_group}"]
    "roles/viewer"                       = ["group:${each.value.admin_group}"]
    "roles/resourcemanager.folderViewer" = ["group:${each.value.admin_group}"]
  }
  # tag_bindings = {
  #   unit = module.organization-tags.tag_values["unit/${each.key}"].id
  # }
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/${each.value.division_key}/${each.key}"
  }
}