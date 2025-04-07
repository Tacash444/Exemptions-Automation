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
  providers = {
    "0-bootstrap" = templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.automation-tf-bootstrap-gcs.name
      name          = "bootstrap"
      sa            = module.automation-tf-bootstrap-sa.email
    })
    "1-resman" = templatefile(local._tpl_providers, {
      backend_extra = null
      bucket        = module.automation-tf-resman-gcs.name
      name          = "resman"
      sa            = module.automation-tf-resman-sa.email
    })
  }
  tfvars = {
    automation = {
      cicd_identity_pool = google_iam_workload_identity_pool.cicd_pool.name
      cicd_identity_provider = {
        issuer_uri = google_iam_workload_identity_pool_provider.cicd_provider.oidc[0].issuer_uri
        name       = google_iam_workload_identity_pool_provider.cicd_provider.name
      }
      auto_wif_sa    = module.auto-wif-sa.iam_email
      cicd_wif_sa    = module.cicd-tf-wif-sa.iam_email
      project_id     = module.automation-project.project_id
      project_number = module.automation-project.number
      service_accounts = {
        bootstrap = module.automation-tf-bootstrap-sa.email
        resman    = module.automation-tf-resman-sa.email
      }
      identity_providers_defs = local.identity_providers_defs
    }
    tf_apply_auto_sa = var.tf_apply_auto_sa
    folder_ids = {
      global_shared = module.global-shared-services-folder.id
      iac           = module.global-iac-folder.id
    }
    shared_labels = var.shared_labels
    custom_roles = module.organization.custom_role_id
    # logging = {
    #   project_id        = module.log-export-project.project_id
    #   project_number    = module.log-export-project.number
    #   writer_identities = module.organization.sink_writer_identities
    # }
    org_policy_tags = {
      key_id = (
        module.organization.tag_keys[var.org_policies_config.tag_name].id
      )
      key_name = var.org_policies_config.tag_name
      values = {
        for k, v in module.organization.tag_values :
        split("/", k)[1] => v.id
      }
    }
    github = var.github
  }
  tfvars_globals = {
    global_billing  = var.global_billing
    groups           = local.principals
    locations        = var.locations
    organization     = var.organization
    prefix           = var.prefix
    billing_accounts = var.billing_accounts
  }
}

output "automation" {
  description = "Automation resources."
  value       = local.tfvars.automation
}

# output "billing_dataset" {
#   description = "BigQuery dataset prepared for billing export."
#   value       = try(module.billing-export-dataset[0].id, null)
# }

output "custom_roles" {
  description = "Organization-level custom roles."
  value       = module.organization.custom_role_id
}

output "project_ids" {
  description = "Projects created by this stage."
  value = {
    automation     = module.automation-project.project_id
    # billing-export = try(module.billing-export-project[0].project_id, null)
    # log-export     = module.log-export-project.project_id
  }
}

# ready to use provider configurations for subsequent stages when not using files
output "providers" {
  # tfdoc:output:consumers stage-01
  description = "Terraform provider files for this stage and dependent stages."
  sensitive   = true
  value       = local.providers
}

output "service_accounts" {
  description = "Automation service accounts created by this stage."
  value = {
    bootstrap = module.automation-tf-bootstrap-sa.email
    resman    = module.automation-tf-resman-sa.email
  }
}

# ready to use variable values for subsequent stages
output "tfvars" {
  description = "Terraform variable files for the following stages."
  sensitive   = true
  value       = local.tfvars
}

