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
  _tpl_providers = "${path.module}/templates/providers.tf.tpl"
  folder_ids = merge(
    {
      networking = try(module.branch-network-folder.id, null)
      security   = try(module.branch-security-folder.id, null)
      billing    = module.branch-billing-folder.id
      logging    = try(module.branch-logging-folder.id, null)
      iac        = var.folder_ids.iac
    },
  )
  auto_tfvars = {
    for workload, sub in local.research_workloads :
    "3-pf-${workload}" => {
      factories_config = {
        projects_data_path_prefix = var.factories_config.projects_dir
        net_data_path             = "${var.outputs_location}/data/2-networking"
        subunit                   = sub
        workload                  = workload
      }
    }
  }
  providers = merge(
    {
      "2-security" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-security-gcs.name
        name          = "security"
        sa            = module.branch-security-sa.email
      })
    },
    {
      "2-shared-projects" = templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-shared-projects-gcs.name
        name          = "shared-projects"
        sa            = module.branch-shared-projects-sa.email
      })
    },
    {
      for k, v in toset(local.pf-states) :
      "3-pf-${v}" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.pf-gcs[k].name
        name          = "${v}-pf"
        sa            = module.pf-sas[k].email
      })
    },
    {
      for v, k in toset(var.environments_networking) :
      "2-networking-${k}" => templatefile(local._tpl_providers, {
        backend_extra = null
        bucket        = module.branch-env-network-gcs[k].name
        name          = "networking-${k}"
        sa            = module.branch-env-network-sa[k].email
      })
    },
  )
  service_accounts = merge(
    {
      for key, value in var.automation.service_accounts : key => "serviceAccount:${value}"
    },
    {
      security      = module.branch-security-sa.iam_email
      shared-projects = module.branch-shared-projects-sa.iam_email
      automations   = module.branch-automations-sa.iam_email
      auto_tf_apply = var.tf_apply_auto_sa
    },
    {
      for key, value in toset(local.pf-states) :
      "project-factory-${value}" => module.pf-sas[value].iam_email
    },
    {
      for key, value in module.branch-env-network-sa :
      "networking-${key}" => value.iam_email
    }
  )
  tfvars = {
    folder_ids                        = local.folder_ids
    service_accounts                  = local.service_accounts
    tag_keys                          = { for k, v in try(module.organization.tag_keys, {}) : k => v.id }
    tag_names                         = var.tag_names
    tag_values                        = { for k, v in try(module.organization.tag_values, {}) : k => v.id }
    subunits                          = local.out_subunits
    environments                      = var.environments
    integration_subunits              = local.out_integration_subunits
    research_workloads                = local.research_workloads
  }
  out_subunits = {
    for subunit_key, subunit_value in local.subunits : subunit_key => {
      name            = subunit_value.descriptive_name
      environments    = var.environments
      unit            = subunit_value.unit_key
      division        = subunit_value.division_key
      billing_account = local.units[subunit_value.unit_key].billing_account
      folder_ids = merge({
        "${subunit_key}" = module.subunits-folder[subunit_key].id
        },
        concat([
          for env in var.environments : {
            "${subunit_key}/${env}" = module.subunits-env-folder["${subunit_key}-${env}"].id
          }
          ],
          [
            { "${subunit_key}/integration/services/" = module.subunits-int-shared-services-folder[subunit_key].id }
          ],
      )...)
    }
  }
  out_integration_subunits = {
    for subunit_key, subunit_value in local.integration_subunits : subunit_key => {
      name            = subunit_value.descriptive_name
      environments    = var.environments
      unit            = subunit_value.unit_key
      division        = subunit_value.division_key
      billing_account = local.units[subunit_value.unit_key].billing_account
      folder_ids = merge({
        "${subunit_key}" = module.subunits-folder[subunit_key].id
        },
        concat([
          for env in var.environments : {
            "${subunit_key}/${env}" = module.subunits-env-folder["${subunit_key}-${env}"].id
          }
          ],
          [
            { "${subunit_key}/integration/services/" = module.subunits-int-shared-services-folder[subunit_key].id }
          ],
      )...)
    }
  }
}

output "project_factories" {
  description = "Data for the project factories stage."
  value = {
    # dev = {
    #   bucket = module.branch-pf-dev-gcs[0].name
    #   sa     = module.branch-pf-dev-sa[0].email
    # }
    # prod = {
    #   bucket = module.branch-pf-prod-gcs[0].name
    #   sa     = module.branch-pf-prod-sa[0].email
    # }
  }
}

# ready to use provider configurations for subsequent stages
output "providers" {
  # tfdoc:output:consumers 02-networking 02-security 03-dataplatform xx-sandbox xx-teams
  description = "Terraform provider files for this stage and dependent stages."
  sensitive   = true
  value       = local.providers
}


output "security" {
  # tfdoc:output:consumers 02-security
  description = "Data for the networking stage."
  value = {
    folder          = module.branch-security-folder.id
    gcs_bucket      = module.branch-security-gcs.name
    service_account = module.branch-security-sa.iam_email
  }
}

output "subunits" {
  description = "Subnits configuration data."
  value       = local.out_subunits
}

# ready to use variable values for subsequent stages
output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}
