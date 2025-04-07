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

# tfdoc:file:description Billing resources for external billing use cases.

locals {
  ext_billing = merge(
    # {
    #   for k, v in module.branch-env-network-sa : "${v.iam_email}-${local.units[k].billing_account.id}" => {
    #     billing_account = local.units[k].billing_account.id
    #     sa              = v.iam_email
    #   } if !local.units[k].billing_account.created_in_org
    # },
    # {
    #   for k, v in var.billing_accounts : "${module.branch-env-network-sa.iam_email}-${k}" => {
    #     billing_account = v.id
    #     sa              = module.branch-env-network-sa.iam_email
    #   } if !v.created_in_org
    # },
    merge([
      for k, v in var.billing_accounts :
      { for work, sub in local.research_workloads :"${module.pf-sas[work].iam_email}-${k}" => {
        billing_account     = v.id
        sa = module.pf-sas[work].iam_email
      } } if !v.created_in_org
    ]...),

    merge([
      for k, v in var.billing_accounts :
      { for env_sub in local.environments_subunits :"${module.pf-sas[env_sub].iam_email}-${k}" => {
        billing_account     = v.id
        sa = module.pf-sas[env_sub].iam_email
      } } if !v.created_in_org
    ]...),

    merge([
      for k, v in var.billing_accounts :
      { for net_sa_key, net_sa_value in module.branch-env-network-sa :"${net_sa_value.iam_email}-${k}" => {
        billing_account     = v.id
        sa = net_sa_value.iam_email
      } } if !v.created_in_org
    ]...),

    {
      for k, v in var.billing_accounts : "${module.branch-security-sa.iam_email}-${k}" => {
        billing_account = v.id
        sa              = module.branch-security-sa.iam_email
      } if !v.created_in_org
    },
    {
      for k, v in var.billing_accounts : "${module.branch-shared-projects-sa.iam_email}-${k}" => {
        billing_account = v.id
        sa              = module.branch-shared-projects-sa.iam_email
      } if !v.created_in_org
    },
  )

}

# billing account in same org (resources is in the organization.tf file)

# standalone billing account

resource "google_billing_account_iam_member" "billing_ext_user" {
  for_each           = local.ext_billing
  billing_account_id = each.value.billing_account
  role               = "roles/billing.user"
  member             = each.value.sa
}

resource "google_billing_account_iam_member" "billing_ext_costsmanager" {
  for_each           = local.ext_billing
  billing_account_id = each.value.billing_account
  role               = "roles/billing.costsManager"
  member             = each.value.sa
}
