locals {
  divisions_billing = {
    for key, value in local.divisions : key => merge(value, {
      billing_account = var.billing_accounts[key]
    }) if try(var.billing_accounts[value.division_key].created_in_org, false)
  }
}

module "divisions-folder" {
  source   = "../modules/folder"
  for_each = local.divisions
  parent   = "organizations/${var.organization.id}"
  name     = each.value.descriptive_name
  iam = {
    "roles/iap.tunnelResourceAccessor"   = ["group:${each.value.admin_group}"]
    "roles/logging.admin"                = ["group:${each.value.admin_group}"]
    "roles/monitoring.admin"             = ["group:${each.value.admin_group}"]
    "roles/viewer"                       = ["group:${each.value.admin_group}"]
    "roles/resourcemanager.folderViewer" = ["group:${each.value.admin_group}"]
  }
  # tag_bindings = {
  #   division = module.organization-tags.tag_values["division/${each.key}"].id
  # }

  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/${each.key}"
  }
}

module "divisions-shared-services-folder" {
  source   = "../modules/folder"
  for_each = local.divisions
  parent   = module.divisions-folder[each.key].id
  name     = "Shared Services"
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/${each.key}/shared"
  }
}

module "divisions-billing-folder" {
  source   = "../modules/folder"
  for_each = local.divisions_billing
  parent   = module.divisions-shared-services-folder[each.key].id
  name     = "Billing"
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/${each.key}/shared/billing"
  }
}

module "divisions-billing-project" {
  source          = "../modules/project"
  for_each        = local.divisions_billing
  billing_account = each.value.billing_account.id
  name            = "billing-0"
  parent          = module.divisions-billing-folder[each.key].id
  prefix          = "${var.prefix}-${each.key}"
  iam = {
    "roles/owner" = ["group:${each.value.admin_group}"]
  }
  services = [
    "bigquery.googleapis.com",
    "bigquerydatatransfer.googleapis.com",
    "storage.googleapis.com"
  ]

  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/${each.key}/shared/billing/billing-0"
  }
}

