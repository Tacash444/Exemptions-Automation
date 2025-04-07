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


module "branch-shared-projects-sa" {
  source       = "../modules/iam-service-account"
  project_id   = var.automation.project_id
  name         = "shared-projects"
  display_name = "Terraform shared projects service account."
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
  iam_folder_roles = {
    (var.folder_ids["global_shared"]) = [
        "roles/resourcemanager.projectCreator",
        "roles/resourcemanager.projectDeleter",
        "roles/resourcemanager.folderAdmin",
        "roles/owner",
        "roles/compute.xpnAdmin",
        "roles/storage.admin"
    ]
  }
}


module "branch-shared-projects-gcs" {
  source        = "../modules/gcs"
  project_id    = var.automation.project_id
  name          = "shared-projects-0"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-shared-projects-sa.iam_email]
  }
}