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

variable "shared_automations_project_id" {
  # tfdoc:variable:source 1-resman
  description = "shared_automations_project_id"
  type        = string
}

variable "global_billing" {
  description = "Global Billing account id. If billing account is not part of the same org set `created_in_org` to `false`. To disable handling of billing IAM roles set `no_iam` to `true`."
  type = object({
    account        = string
    created_in_org = optional(bool, true)
    no_iam         = optional(bool, false)
  })
  nullable = false
}

variable "billing_accounts" {
  description = "Billing account id of specific units"
  type = map(object({
    id              = string
    organization_id = number
    created_in_org  = optional(bool, true)
  }))
}
variable "custom_roles" {
  # tfdoc:variable:source 0-bootstrap
  description = "Custom roles defined at the org level, in key => id format."
  type = object({
    service_project_network_admin = string
  })
  default = null
}

variable "dns" {
  description = "DNS configuration."
  type = object({
    enable_logging = optional(bool, true)
    resolvers      = optional(list(string), [])
  })
  default  = {}
  nullable = false
}

variable "factories_config" {
  description = "Configuration for network resource factories."
  type = object({
    data_dir     = string
    projects_dir = optional(string)

  })
  nullable = false
  validation {
    condition     = var.factories_config.data_dir != null
    error_message = "Data folder needs to be non-null."
  }
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
  description = "Path where providers and tfvars files for the following stages are written. Leave empty to disable."
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

variable "region" {
  description = "Region definitions."
  type        = string
  default     = "me-west1"
}

variable "service_accounts" {
  # tfdoc:variable:source 1-resman
  description = "Automation service accounts in name => email format."
  type = object({
    # project-factory-dev  = string
    # project-factory-prod = string
  })
  default = null
}

variable "environments" {
  # tfdoc:variable:source 1-resman
  description = "list of envs"
  type        = list(string)
  default     = null
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

variable "research_workloads" {
  # tfdoc:variable:source 1-resman
  description = "research_workloads configuration data"
  type        = map(string)
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
  })
  nullable = false
  default  = {}
}


variable "folder_ids" {
  description = "Optional parents for projects created here in folders/nnnnnnn format. Null values will use the organization as parent."
  type = object({
    automation = optional(string)
    billing    = optional(string)
    logging    = optional(string)
    security   = optional(string)
    networking = optional(string)
  })
  default  = {}
  nullable = false
}

variable "vpc_sc" {
  # tfdoc:variable:source 2-security
  description = "perimeters"
  type        = map(string)
}

variable "shared_labels" {
  description = "labels for shared projects"
  type        = map(string)
  default     = { "department" : "lz-shared", "costcenter" : "lz-shared" }
}
