
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

module "workload-folder" {
  source   = "../modules/folder"
  parent   = var.subunits[var.factories_config.subunit].folder_ids["${var.factories_config.subunit}/${local.environment}"]
  name     = var.factories_config.workload
}

module "projects" {
  source          = "../modules/project"
  for_each        = local.projects
  billing_account = each.value.billing_account
  name            = each.key
  parent          = module.workload-folder.id
  prefix          = var.prefix

  auto_create_network        = try(each.value.auto_create_network, false)
  compute_metadata           = try(each.value.compute_metadata, {})
  contacts                   = try(each.value.contacts, null)
  default_service_account    = try(each.value.default_service_account, "keep")
  descriptive_name           = try(each.value.descriptive_name, null)
  iam                        = try(each.value.iam, {})
  iam_bindings               = try(each.value.iam_bindings, {})
  iam_bindings_additive      = try(each.value.iam_bindings_additive, {})
  iam_by_principals          = try(each.value.iam_by_principals, {})
  labels                     = try(each.value.labels, null)
  lien_reason                = try(each.value.lien_reason, null)
  logging_data_access        = try(each.value.logging_data_access, {})
  logging_exclusions         = try(each.value.logging_exclusions, {})
  logging_sinks              = try(each.value.logging_sinks, {})
  metric_scopes              = try(each.value.metric_scopes, null)
  org_policies               = try(each.value.org_policies, {})
  service_encryption_key_ids = try(each.value.service_encryption_key_ids, {})
  services                   = concat(local.default_services, try(each.value.services, null))
  tag_bindings               = try(each.value.tag_bindings, null)

  shared_vpc_service_config = {
    # $${subunit}/$${environment}/$${zone} or common/$${environment}/$${zone}
    host_project       = module.workload-net-project.project_id
    service_iam_grants = concat(local.default_services, try(each.value.services, []))
    service_agent_iam  = transpose(merge(transpose(local.default_robots_iam), transpose(try(each.value.robots_iam, {}))))
  }

  vpc_sc = {
    perimeter_name = var.vpc_sc["${var.factories_config.workload}_${local.environment}"]
  }
}

module "default-bucket" {
  source        = "../modules/gcs"
  for_each      = local.projects
  project_id    = module.projects[each.key].id
  name          = "${each.key}-default-bucket"
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
}
