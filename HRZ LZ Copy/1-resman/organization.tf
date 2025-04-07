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

# tfdoc:file:description Organization policies.

locals {
  tags = var.tags
}

module "organization-logging" {
  # Preconfigure organization-wide logging settings to ensure project
  # log buckets (_Default, _Required) are created in the location
  # specified by `var.locations.logging`. This separate
  # organization-block prevents circular dependencies with later
  # project creation.
  source          = "../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  logging_settings = {
    storage_location = var.locations.logging
  }
}

module "organization" {
  source          = "../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  # additive bindings via delegated IAM grant set in stage 0
  iam_bindings_additive = local.iam_bindings_additive
}

moved {
  from = module.organization.google_tags_tag_key.default["environment"]
  to   = module.organization-tags.google_tags_tag_key.default["environment"]

}
moved {
  from = module.organization.google_tags_tag_key.default["context"]
  to   = module.organization-tags.google_tags_tag_key.default["context"]
}

# tags are managed through separate module instance to avoid dependency cycle,
# as the iam_bindings add permissions for SA that are located under folders that
# are tagged with values below
module "organization-tags" {
  source          = "../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  # do not assign tagViewer or tagUser roles here on tag keys and values as
  # they are managed authoritatively and will break multitenant stages
  tags = merge(local.tags, {
    (var.tag_names.context) = {
      description = "Resource management context."
      iam         = {}
      values = {
        data         = {}
        gke          = {}
        gcve         = {}
        networking   = {}
        sandbox      = {}
        security     = {}
        interconnect = {}
      }
    }
    environment = {
      description = "Environments."
      iam         = {}
      values = {
        for env in var.environments : env => {}
      }
    }
    division = {
      description = "Division."
      iam         = {}
      values = {
        for k, v in local.divisions : k => {}
      }
    }
    subunit = {
      description = "Subunits."
      iam         = {}
      values = {
        for key, value in local.subunits : key => {}
      }
    }
    unit = {
      description = "Unit."
      iam         = {}
      values = {
        for k, v in local.units : k => {}
      }
    }
  })
}
