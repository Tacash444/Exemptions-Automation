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

# automation service accounts
module "branch-automations-sa" {
  source       = "../modules/iam-service-account"
  project_id   = var.automation.project_id
  name         = "prod-resman-auto-0"
  display_name = "Terraform Automations service account."
  prefix       = var.prefix

  iam_bindings_additive = {
    "auto-token-creator" = {
      role   = "roles/iam.serviceAccountTokenCreator"
      member = var.automation.auto_wif_sa
    },
    "tf-apply-token-creator" = {
      role   = "roles/iam.serviceAccountTokenCreator"
      member = var.tf_apply_auto_sa
    }
  }
  iam_project_roles = {
    (var.automation.project_id) = ["roles/serviceusage.serviceUsageConsumer",
      "roles/storage.admin",
      "roles/iam.serviceAccountCreator",
      "roles/resourcemanager.projectIamAdmin",
      "roles/cloudbuild.workerPoolOwner",
      "roles/cloudfunctions.admin",
      "roles/run.admin",
      "roles/iam.serviceAccountUser",
      "roles/workflows.admin",
    "roles/iam.serviceAccountAdmin"]
  }
}

module "branch-automation-gcs" {
  source        = "../modules/gcs"
  project_id    = var.automation.project_id
  name          = "prod-resman-auto-1"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.branch-automations-sa.iam_email]
  }
}

