/**
 * Copyright 2024 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  divisions = {
    for f in fileset("${var.factories_config.data_dir}/divisions", "*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.factories_config.data_dir}/divisions/${f}"))
  }

  units = merge([
    for key, value in local.divisions :
    { for unit_key, unit_value in value.units : unit_key => {
      division_key     = key
      descriptive_name = unit_value.descriptive_name
      sub_units        = unit_value.sub_units
      admin_group      = unit_value.admin_group
      billing_account  = var.billing_accounts[try(unit_value.billing_account, key)]
      integration      = try(unit_value.integration, false)
    } }
  ]...)

  subunits = merge([
    for unit_key, unit_value in local.units :
    { for subunit_key, subunit_value in unit_value.sub_units : subunit_key => {
      unit_key         = unit_key
      descriptive_name = subunit_value.descriptive_name
      admin_group      = try(subunit_value.admin_group, unit_value.admin_group)
      division_key     = unit_value.division_key
    } }
  ]...)

  integration_subunits = merge([
    for unit_key, unit_value in local.units :
    { for subunit_key, subunit_value in unit_value.sub_units : subunit_key => {
      unit_key         = unit_key
      descriptive_name = subunit_value.descriptive_name
      admin_group      = try(subunit_value.admin_group, unit_value.admin_group)
      division_key     = unit_value.division_key
    } } if unit_value.integration == true
  ]...)

  research_workloads = merge([
    for sub_key, sub_value in local.subunits :
    { for workload in distinct([for f in fileset("${var.factories_config.projects_dir}/${sub_key}/research", "**/*.yaml") : dirname(f)]) :
    workload => sub_key }
  ]...)

  environments_subunits = flatten([
    for env in var.environments :
    [
      for key, value in local.subunits :
      "${key}-${substr(env, 0, 3)}" if env != "research"
    ]
  ])

  gcs_storage_class = (
    length(split("-", var.locations.gcs)) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )

  principals = {
    for k, v in var.groups : k => (
      can(regex("^[a-zA-Z]+:", v))
      ? v
      : "group:${v}@${var.organization.domain}"
    )
  }

  sa_principals = {
    for k, v in var.service_accounts : k => (
      "serviceAccount:${v}"
    )
  }

  default_budget_config = {
    thresholds = [
      {
        percent          = 0.5
        forecasted_spend = false
      },
      {
        percent          = 0.8
        forecasted_spend = false
      }
    ]
  }

  prefix = join("-", compact([var.prefix, "prod"]))
}


module "branch-billing-folder" {
  source = "../modules/folder"
  parent = var.folder_ids.global_shared
  name   = "Billing"
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/global-shared/billing"
  }
}

module "branch-network-folder" {
  source = "../modules/folder"
  parent = var.folder_ids.global_shared
  name   = "Network"
  iam = {
    for key, value in toset(local._network_folder_iam) : value => [module.branch-env-network-sa["research"].iam_email]
  }
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/global-shared/network"
  }
}


module "branch-logging-folder" {
  source = "../modules/folder"
  parent = var.folder_ids.global_shared
  name   = "Logging"
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/global-shared/logging"
  }
}

module "branch-security-folder" {
  source = "../modules/folder"
  parent = var.folder_ids.global_shared
  name   = "Security"
  iam_by_principals = {
    (local.principals.gcp-security-admins) = [
      "roles/editor"
    ]
  }
  iam = local._security_folder_iam
  tag_bindings = {
    context = module.organization-tags.tag_values["${var.tag_names.context}/security"].id
  }

  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/global-shared/security"
  }
}
