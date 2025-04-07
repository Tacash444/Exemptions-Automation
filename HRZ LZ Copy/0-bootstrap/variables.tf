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

variable "github" {
  description = "github repo and org for tf"
  type = object({
    org  = string
    repo = string
  })
  default = null
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

variable "bootstrap_user" {
  description = "Email of the nominal user running this stage for the first time."
  type        = string
  default     = null
}

variable "custom_roles" {
  description = "Map of role names => list of permissions to additionally create at the organization level."
  type        = map(list(string))
  nullable    = false
  default     = {}
}

variable "essential_contacts" {
  description = "Email used for essential contacts, unset if null."
  type        = string
  default     = null
}

variable "factories_config" {
  description = "Configuration for the resource factories or external data."
  type = object({
    checklist_data = optional(string)
    data_dir       = optional(string)
  })
  nullable = false
  default  = {}
}


variable "groups" {
  # https://cloud.google.com/docs/enterprise/setup-checklist
  description = "Group names or IAM-format principals to grant organization-level permissions. If just the name is provided, the 'group:' principal and organization domain are interpolated."
  type = object({
    gcp-billing-admins      = optional(string, "gcp-organization-admins")
    gcp-devops              = optional(string, "gcp-organization-admins")
    gcp-network-admins      = optional(string, "gcp-organization-admins")
    gcp-organization-admins = optional(string, "gcp-organization-admins")
    gcp-security-admins     = optional(string, "gcp-organization-admins")
    gcp-security-soc        = optional(string, "gcp-organization-admins")
    # aliased to gcp-devops as the checklist does not create it
    gcp-support           = optional(string, "gcp-organization-admins")
    gcp-fw-admins         = optional(string, "gcp-organization-admins")
    gcp-mamram-sa         = optional(string, "gcp-organization-admins")
    gcp-data-admins       = optional(string, "gcp-organization-admins")
    gcp-distribute-admins = optional(string, "gcp-organization-admins")
    gcp-finops-admins     = optional(string, "gcp-organization-admins")
  })
  nullable = false
  default  = {}
}

variable "iam" {
  description = "Organization-level custom IAM settings in role => [principal] format."
  type        = map(list(string))
  nullable    = false
  default     = {}
}

variable "iam_bindings_additive" {
  description = "Organization-level custom additive IAM bindings. Keys are arbitrary."
  type = map(object({
    member = string
    role   = string
    condition = optional(object({
      expression  = string
      title       = string
      description = optional(string)
    }))
  }))
  nullable = false
  default  = {}
}

variable "iam_by_principals" {
  description = "Authoritative IAM binding in {PRINCIPAL => [ROLES]} format. Principals need to be statically defined to avoid cycle errors. Merged internally with the `iam` variable."
  type        = map(list(string))
  default     = {}
  nullable    = false
}

variable "locations" {
  description = "Optional locations for GCS, BigQuery, and logging buckets created here."
  type = object({
    bq      = optional(string, "me-west1")
    gcs     = optional(string, "me-west1")
    logging = optional(string, "me-west1")
    pubsub  = optional(list(string), [])
  })
  nullable = false
  default  = {}
}

# See https://cloud.google.com/architecture/exporting-stackdriver-logging-for-security-and-access-analytics
# for additional logging filter examples
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

variable "org_policies_config" {
  description = "Organization policies customization."
  type = object({
    constraints = optional(object({
      allowed_policy_member_domains = optional(list(string), [])
    }), {})
    import_defaults = optional(bool, false)
    tag_name        = optional(string, "org-policies")
    tag_values = optional(map(object({
      description = optional(string, "Managed by the Terraform organization module.")
      iam         = optional(map(list(string)), {})
      id          = optional(string)
    })), {})
  })
  default = {}
}

variable "organization" {
  description = "Organization details."
  type = object({
    id          = number
    domain      = optional(string)
    customer_id = optional(string)
  })
}

variable "outputs_location" {
  description = "Enable writing provider, tfvars and CI/CD workflow files to local filesystem. Leave null to disable."
  type        = string
  default     = null
}

variable "tf_apply_auto_sa" {
  description = "tf_apply_auto_sa"
  type        = string
  default     = null
}

variable "prefix" {
  description = "Prefix used for resources that need unique names. Use 9 characters or less."
  type        = string
  validation {
    condition     = try(length(var.prefix), 0) < 10
    error_message = "Use a maximum of 9 characters for prefix."
  }
}

variable "shared_labels" {
  description = "labels for shared projects"
  type        = map(string)
  default     = { "department" : "lz", "costcenter" : "sharedresource", "account": "shared" }
}
