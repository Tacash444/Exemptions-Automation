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
    projects_data_path         = string
    firewall_named_ranges_file = optional(string)
  })
  nullable = false
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

variable "folder_ids" {
  # tfdoc:variable:source 1-resman
  description = "Shared folders created by the resman stage."
  type = object({
    # global_shared = string
    # iac           = string
    networking = string
    security   = string
    billing    = string
    logging    = string
    iac        = string
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

variable "log_sinks" {
  description = "Org-level log sinks, in name => {type, filter} format."
  type = map(object({
    filter = string
    type   = string
  }))
  default = {
    audit-logs = {
      filter = ""
      type   = "logging"
    }
    vpc-sc = {
      filter = "protoPayload.metadata.@type=\"type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata\""
      type   = "logging"
    }
    workspace-audit-logs = {
      filter = "logName:\"/logs/cloudaudit.googleapis.com%2Fdata_access\" and protoPayload.serviceName:\"login.googleapis.com\""
      type   = "logging"
    }
  }
  validation {
    condition = alltrue([
      for k, v in var.log_sinks :
      contains(["bigquery", "logging", "pubsub", "storage"], v.type)
    ])
    error_message = "Type must be one of 'bigquery', 'logging', 'pubsub', 'storage'."
  }
}

variable "shared_auto_github" {
  type = object({
    repo = string
    org  = string
  })
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}