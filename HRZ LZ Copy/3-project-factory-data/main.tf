
/**
 * Copyright 2022 Google LLC
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

# tfdoc:file:description Project factory.

module "projects" {
  source          = "../modules/project"
  for_each        = local.projects
  billing_account = each.value.billing_account
  name            = each.value.name
  parent          = each.value.parent
  iam_bindings_additive      = try(each.value.iam_bindings_additive, {})
  descriptive_name           = try(each.value.descriptive_name, null)
  labels                     = try(each.value.labels, null)
  org_policies               = try(each.value.org_policies, {})
  services                   = concat(local.default_services, try(each.value.services, []))

  vpc_sc = {
    perimeter_name = var.vpc_sc["${each.key}_${local.environment}"]
  }
}

module "data-bucket" {
  source        = "../modules/gcs"
  for_each      = local.projects
  project_id    = module.projects[each.key].id
  name          = "${each.value.name}-data-bucket"
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.legacyBucketOwner" = concat(each.value.owner, [var.groups.gcp-organization-admins])
  }
}