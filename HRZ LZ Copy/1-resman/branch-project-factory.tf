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
# tfdoc:file:description Project factory stage resources.

# automation service accounts

# uncomment first run to move the state between buckets

locals {
  pf-states = concat(keys(local.research_workloads), local.environments_subunits)
}

module "pf-sas" {
  source       = "../modules/iam-service-account"
  for_each     = toset(local.pf-states)
  project_id   = var.automation.project_id
  name         = "${each.value}-pf"
  display_name = "Terraform ${each.value} project factory service account."
  prefix       = var.prefix
  iam_project_roles = {
    (var.automation.project_id) = [
      "roles/serviceusage.serviceUsageConsumer"
    ]
    # (module.branch-subunit-services-cicd-projects[split("_", each.key)[0]].id) = [
    #   "roles/artifactregistry.admin"
    # ]
  }
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      var.automation.cicd_wif_sa,
      var.tf_apply_auto_sa
    ])
  }
}

module "pf-gcs" {
  source        = "../modules/gcs"
  for_each      = toset(local.pf-states)
  project_id    = var.automation.project_id
  name          = "${each.value}-pf"
  prefix        = var.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.pf-sas[each.key].iam_email]
  }
}
