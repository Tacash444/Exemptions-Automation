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

# defaults for variables marked with global tfdoc annotations, can be set via
# the tfvars file generated in stage 00 and stored in its outputs

variable "automation" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    project_id         = string
    project_number     = string
    auto_wif_sa        = string
    cicd_wif_sa        = string
    cicd_identity_pool = string
    identity_providers_defs = object({
      github = object({
        issuer_uri        = string
        attribute_mapping = map(string)
      })
    })
    cicd_identity_provider = object({
      name       = string
      issuer_uri = string
    })
    service_accounts = object({
      resman    = string
      bootstrap = string
    })
  })
}

variable "folder_ids" {
  # tfdoc:variable:source 0-bootstrap
  description = "Automation resources created by the bootstrap stage."
  type = object({
    global_shared = string
    iac           = string
  })
}


variable "global_billing" {
  # tfdoc:variable:source 0-bootstrap
  description = "Global Billing account id. If billing account is not part of the same org set `created_in_org` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`."
  type = object({
    account        = string
    created_in_org = optional(bool, true)
    no_iam         = optional(bool, false)
  })
  nullable = false
}

variable "custom_roles" {
  # tfdoc:variable:source 0-bootstrap
  description = "Custom roles defined at the org level, in key => id format."
  type        = map(string)
  default     = null
}

variable "environments" {
  description = "Environments to create for each subunit."
  type        = list(string)
  nullable    = false
}

variable "environments_networking" {
  description = "Environments that has networking."
  type        = list(string)
  nullable    = false
}
variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    checklist_data = optional(string)
    data_dir       = optional(string)
    projects_dir  = optional(string)
  })
  nullable = false
  default  = {}
}

variable "groups" {
  # tfdoc:variable:source 0-bootstrap
  # https://cloud.google.com/docs/enterprise/setup-checklist
  description = "Group names or IAM-format principals to grant organization-level permissions. If just the name is provided, the 'group:' principal and organization domain are interpolated."
  type = object({
    gcp-billing-admins      = optional(string, "gcp-billing-admins")
    gcp-devops              = optional(string, "gcp-devops")
    gcp-network-admins      = optional(string, "gcp-network-admins")
    gcp-organization-admins = optional(string, "gcp-organization-admins")
    gcp-security-admins     = optional(string, "gcp-security-admins")
    gcp-fw-admins           = optional(string, "gcp-vpc-network-admins")
    gcp-data-admins         = optional(string, "gcp-data-admins")
    gcp-finops-admins       = optional(string, "gcp-finops-admins")
  })
  nullable = false
  default  = {}
}

variable "locations" {
  # tfdoc:variable:source 0-bootstrap
  description = "Optional locations for GCS, BigQuery, and logging buckets created here."
  type = object({
    bq      = string
    gcs     = string
    logging = string
    pubsub  = list(string)
  })
  nullable = false
}

variable "organization" {
  # tfdoc:variable:source 0-bootstrap
  description = "Organization details."
  type = object({
    domain      = string
    id          = number
    customer_id = string
  })
}

variable "outputs_location" {
  description = "Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable."
  type        = string
  default     = null
}

variable "prefix" {
  # tfdoc:variable:source 0-bootstrap
  description = "Prefix used for resources that need unique names. Use 9 characters or less."
  type        = string

  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

variable "tag_names" {
  description = "Customized names for resource management tags."
  type = object({
    context     = optional(string, "context")
    environment = optional(string, "environment")
    tenant      = optional(string, "tenant")
  })
  default  = {}
  nullable = false
  validation {
    condition     = alltrue([for k, v in var.tag_names : v != null])
    error_message = "Tag names cannot be null."
  }
}

variable "tags" {
  description = "Custom secure tags by key name. The `iam` attribute behaves like the similarly named one at module level."
  type = map(object({
    description = optional(string, "Managed by the Terraform organization module.")
    iam         = optional(map(list(string)), {})
    values = optional(map(object({
      description = optional(string, "Managed by the Terraform organization module.")
      iam         = optional(map(list(string)), {})
      id          = optional(string)
    })), {})
  }))
  nullable = false
  default  = {}
  validation {
    condition = alltrue([
      for k, v in var.tags : v != null
    ])
    error_message = "Use an empty map instead of null as value."
  }
}

variable "billing_accounts" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id of specific units"
  type = map(object({
    id              = string
    organization_id = number
    created_in_org  = optional(bool, true)
  }))
}

variable "shared_labels" {
  description = "labels for shared projects"
  type        = map(string)
  default     = { "department" : "lz-shared", "costcenter" : "lz-shared" }
}


variable "region" {
  description = "Region definitions."
  type        = string
  default     = "me-west1"
}


variable "service_accounts" {
  description = "Map of extra service accounts"
  type        = map(string)
  default     = {}
}

variable "create_subunit_zone_cicd_resource" {
  description = "create resource only in prod org"
  type        = bool
  default     = false
}

variable "cloud_run_interconnect_sa" {
  description = "cloud_run_interconnect_sa"
  type        = string
  default     = null
}

variable "tf_apply_auto_sa" {
  description = "tf_apply_auto_sa"
  type        = string
  default     = null
}