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

# tfdoc:file:description Networking stage resources.

locals {
  # FAST-specific IAM
  _envs_iam_sa = [for key, value in module.branch-env-network-sa : value.iam_email]
  _network_folder_iam = [
    # read-write (apply) automation service account
    "roles/logging.admin",
    "roles/owner",
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectCreator",
    "roles/compute.xpnAdmin",
  ]
}

module "branch-env-network-sa" {
  source       = "../modules/iam-service-account"
  for_each     = toset(var.environments_networking)
  project_id   = var.automation.project_id
  name         = "prod-resman-${substr(each.key, 0, 3)}-net-0"
  display_name = "Terraform ${each.key} networking service account."
  prefix       = var.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      var.automation.cicd_wif_sa,
      var.tf_apply_auto_sa
    ])
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer"]
  }
}

module "branch-env-network-gcs" {
  source        = "../modules/gcs"
  for_each      = toset(var.environments_networking)
  project_id    = var.automation.project_id
  name          = "prod-resman-${substr(each.key, 0, 3)}-net-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-env-network-sa[each.key].iam_email]
  }
}
