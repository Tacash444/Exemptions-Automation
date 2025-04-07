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

# tfdoc:file:description Billing export project and dataset.

locals {
  # used here for convenience, in organization.tf members are explicit
  billing_ext_admins = [
    local.principals.gcp-billing-admins,
    local.principals.gcp-organization-admins,
    module.automation-tf-bootstrap-sa.iam_email,
    module.automation-tf-resman-sa.iam_email,
    local.principals.gcp-finops-admins
  ]

  ext_billing = merge(
    {
      for k, v in var.billing_accounts : "${module.automation-tf-bootstrap-sa.iam_email}-${k}" => {
        sa              = module.automation-tf-bootstrap-sa.iam_email
        billing_account = v.id
      } if !v.created_in_org
    },
    {
      for k, v in var.billing_accounts : "${module.automation-tf-resman-sa.iam_email}-${k}" => {
        sa              = module.automation-tf-resman-sa.iam_email
        billing_account = v.id
      } if !v.created_in_org
    },
  )
  billing_mode = (
    var.global_billing.no_iam
    ? null
    : var.global_billing.created_in_org ? "org" : "resource"
  )
}

# billing account in same org (IAM is in the organization.tf file)

# module "billing-export-project" {
#   source          = "../modules/project"
#   count           = local.billing_mode == "org" ? 1 : 0
#   billing_account = var.billing_accounts[var.global_billing.account].id
#   name            = "billing-exp-0"
#   parent = module.branch-billing-folder.id
#   prefix = local.prefix
#   contacts = (
#     var.bootstrap_user != null || var.essential_contacts == null
#     ? {}
#     : { (var.essential_contacts) = ["ALL"] }
#   )
#   iam = {
#     "roles/owner"  = [module.automation-tf-bootstrap-sa.iam_email]
#   }
#   services = [
#     # "cloudresourcemanager.googleapis.com",
#     # "iam.googleapis.com",
#     # "serviceusage.googleapis.com",
#     "bigquery.googleapis.com",
#     "bigquerydatatransfer.googleapis.com",
#     "storage.googleapis.com"
#   ]
# }

# module "billing-export-dataset" {
#   source        = "../modules/bigquery-dataset"
#   count         = local.billing_mode == "org" ? 1 : 0
#   project_id    = module.billing-export-project[0].project_id
#   id            = "billing_export"
#   friendly_name = "Billing export."
#   location      = var.locations.bq
# }

#  billing account
resource "google_billing_account_iam_member" "billing_admin_ext" {
  for_each = local.ext_billing
  billing_account_id = each.value.billing_account
  role               = "roles/billing.admin"
  member             = each.value.sa
}

