/**
 * Copyright 2023 Google LLC
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

variable "access_levels" {
  description = "Access level definitions."
  type = map(object({
    combining_function = optional(string)
    conditions = optional(list(object({
      device_policy = optional(object({
        allowed_device_management_levels = optional(list(string))
        allowed_encryption_statuses      = optional(list(string))
        require_admin_approval           = bool
        require_corp_owned               = bool
        require_screen_lock              = optional(bool)
        os_constraints = optional(list(object({
          os_type                    = string
          minimum_version            = optional(string)
          require_verified_chrome_os = optional(bool)
        })))
      }))
      ip_subnetworks         = optional(list(string), [])
      members                = optional(list(string), [])
      negate                 = optional(bool)
      regions                = optional(list(string), [])
      required_access_levels = optional(list(string), [])
    })), [])
    description = optional(string)
  }))
  default  = {}
  nullable = false
  validation {
    condition = alltrue([
      for k, v in var.access_levels : (
        v.combining_function == null ||
        v.combining_function == "AND" ||
        v.combining_function == "OR"
      )
    ])
    error_message = "Invalid `combining_function` value (null, \"AND\", \"OR\" accepted)."
  }
}

variable "organization" {
  # tfdoc:variable:source 0-bootstrap
  description = "Organization details."
  type = object({
    id = number
  })
}

variable "service_accounts" {
  # tfdoc:variable:source 1-resman
  description = "Service Accounts"
  type        = map(string)
}

variable "outputs_location" {
  description = "Path where providers, tfvars files, and lists for the following stages are written. Leave empty to disable."
  type        = string
  default     = null
}

variable "perimeter_config" {
  type = map(object({
    applications = list(string)
    vpc_accessible_services = optional(object({
      allowed_services   = list(string)
      enable_restriction = bool
    }))
  }))
  default = null
}

variable "dry_run" {
  type    = bool
  default = false
}

variable "research_workloads" {
  # tfdoc:variable:source 1-resman
  description = "research_workloads configuration data"
  type        = map(string)
}

variable "factories_config" {
  description = "Configuration for security resource factories."
  type = object({
    data_dir = string
  })
  nullable = false
  validation {
    condition     = var.factories_config.data_dir != null
    error_message = "Data folder needs to be non-null."
  }
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
    gcp-mamram-sa         = optional(string, "mamram-solution-architects")
  })
  nullable = false
  default  = {}
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

variable "billing_accounts" {
  # tfdoc:variable:source 0-bootstrap
  description = "Billing account id of specific units"
  type = map(object({
    id              = string
    organization_id = number
    created_in_org  = optional(bool, true)
  }))
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

variable "shared_labels" {
  description = "labels for shared projects"
  type        = map(string)
  default     = { "department" : "lz-shared", "costcenter" : "lz-shared-costcenter" }
}

variable "global_perimeters" {
  description = "global permiters"
  type        = list(string)
  default     = null
}

variable "all_vpcsc_exemp" {
  description = "all sa that needs access to all perimiters"
  type        = list(string)
  default     = null
}
