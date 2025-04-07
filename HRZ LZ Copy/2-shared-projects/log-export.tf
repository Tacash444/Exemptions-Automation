#  /**
#  * Copyright 2024 Google LLC
#  *
#  * Licensed under the Apache License, Version 2.0 (the "License");
#  * you may not use this file except in compliance with the License.
#  * You may obtain a copy of the License at
#  *
#  *      http://www.apache.org/licenses/LICENSE-2.0
#  *
#  * Unless required by applicable law or agreed to in writing, software
#  * distributed under the License is distributed on an "AS IS" BASIS,
#  * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  * See the License for the specific language governing permissions and
#  * limitations under the License.
#  */

# # tfdoc:file:description Audit log project and sink.

locals {
  prefix = join("-", compact([var.prefix, "prod"]))
  gcs_storage_class = (
    length(split("-", var.locations.gcs)) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )
  log_sink_destinations = merge(
    # use the same dataset for all sinks with `bigquery` as  destination
    {
      for k, v in var.log_sinks :
      k => module.log-export-dataset[0] if v.type == "bigquery"
    },
    # use the same gcs bucket for all sinks with `storage` as destination
    {
      for k, v in var.log_sinks :
      k => module.log-export-gcs[0] if v.type == "storage"
    },
    # use separate pubsub topics and logging buckets for sinks with
    # destination `pubsub` and `logging`
    module.log-export-pubsub,
    module.log-export-logbucket
  )
  log_types = toset([for k, v in var.log_sinks : v.type])
}

# # one log export per type, with conditionals to skip those not needed

module "log-export-dataset" {
  source        = "../modules/bigquery-dataset"
  count         = contains(local.log_types, "bigquery") ? 1 : 0
  project_id    = module.projects["audit-logs"].project_id
  id            = "logs"
  friendly_name = "Audit logs export."
  location      = var.locations.bq
}

module "log-export-gcs" {
  source        = "../modules/gcs"
  count         = contains(local.log_types, "storage") ? 1 : 0
  project_id    = module.projects["audit-logs"].project_id
  name          = "logs"
  prefix        = local.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
}

module "log-export-logbucket" {
  source        = "../modules/logging-bucket"
  for_each      = toset([for k, v in var.log_sinks : k if v.type == "logging"])
  parent_type   = "project"
  parent        = module.projects["audit-logs"].project_id
  id            = each.key
  location      = var.locations.logging
  log_analytics = { enable = true }

  # # org-level logging settings ready before we create any logging buckets
  # depends_on = [module.organization-logging]
}

module "log-export-pubsub" {
  source     = "../modules/pubsub"
  for_each   = toset([for k, v in var.log_sinks : k if v.type == "pubsub"])
  project_id = module.projects["audit-logs"].project_id
  name       = each.key
  regions    = var.locations.pubsub
}

module "organization" {
  source          = "../modules/organization"
  organization_id = "organizations/${var.organization.id}"

  logging_sinks = {
    for name, attrs in var.log_sinks : name => {
      bq_partitioned_table = attrs.type == "bigquery"
      destination          = local.log_sink_destinations[name].id
      filter               = attrs.filter
      type                 = attrs.type
    }
  }
}