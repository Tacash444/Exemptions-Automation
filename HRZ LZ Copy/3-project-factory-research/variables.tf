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

#TODO: tfdoc annotations

variable "billing_accounts" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id of specific units"
  type = map(object({
    id              = string
    organization_id = number
    created_in_org  = optional(bool, true)
  }))
}

variable "factories_config" {
  description = "Path to folder with YAML resource description data files."
  type = object({
    # projects_data_path         = string
    projects_data_path_prefix = string
    subunit     = string
    workload    = string
    net_data_path = string
    firewall_named_ranges_file = optional(string)
    #    budgets = optional(object({
    #      billing_account       = string
    #      budgets_data_path     = string
    #      notification_channels = optional(map(any), {})
    #    }))
  })
  nullable = false
}

variable "swp_ip" {
  # tfdoc:variable:source 2-networking
  description = "swp_ip"
  type        = string
  # nullable    = false
}

variable "global_vpc" {
  # tfdoc:variable:source 2-networking
  description = "global_vpc self link"
  type        = string
  # nullable    = false
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

variable "region" {
  description = "Region definitions."
  type        = string
  default     = "me-west1"
}

variable "subunits" {
  # tfdoc:variable:source 1-resman
  description = "subunit configuration data"
  type = map(object({
    name = string
    billing_account = object({
      id              = string
      organization_id = number
      created_in_org  = optional(bool, true)
    })
    environments = list(string)
    folder_ids   = map(string)
    unit         = string
    division     = string
    })
  )
}

variable "vpc_sc" {
  # tfdoc:variable:source 2-security
  description = "Map of vpc perimeter names."
  type        = map(string)
  nullable    = false
}

variable "legacy_subnets" {
  type    = list(string)
  default = []
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

variable "organization" {
  description = "Organization details."
  type = object({
    id          = number
    domain      = optional(string)
    customer_id = optional(string)
  })
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
