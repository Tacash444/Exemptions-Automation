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
  # naming: environment used in most resource names
  prefix = join("-", compact([var.prefix, "prod"]))
}

module "global-shared-services-folder" {
  source = "../modules/folder"
  parent = "organizations/${var.organization.id}"
  name   = "Global Shared Services"
  # factories_config = {
  #   org_policies = "${var.factories_config.data_dir}/org-policies/global-shared/"
  # }
}

module "global-iac-folder" {
  source = "../modules/folder"
  parent = module.global-shared-services-folder.id
  name   = "IaC"
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/org-policies/global-shared/iac"
  }
}

# module "branch-billing-folder" {
#   source = "../modules/folder"
#   parent = module.global-shared-services-folder.id
#   name   = "Billing"
#   # factories_config = {
#   #   org_policies = "${var.factories_config.data_dir}/org-policies/global-shared/billing"
#   # }
# }

# module "branch-logging-folder" {
#   source = "../modules/folder"
#   parent = module.global-shared-services-folder.id
#   name   = "Logging"
#   factories_config = {
#     org_policies = "${var.factories_config.data_dir}/org-policies/global-shared/logging"
#   }
# }
