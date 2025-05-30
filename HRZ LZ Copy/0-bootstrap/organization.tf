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

# tfdoc:file:description Organization-level IAM.

locals {
  # reassemble logical bindings into the formats expected by the module
  _iam_bindings = merge(
    local.iam_domain_bindings,
    local.iam_sa_bindings,
    local.iam_user_bootstrap_bindings,
    {
      for k, v in local.iam_principal_bindings : k => {
        authoritative = []
        additive      = v.additive
      }
    }
  )
  _iam_bindings_auth = flatten([
    for member, data in local._iam_bindings : [
      for role in data.authoritative : {
        member = member
        role   = role
      }
    ]
  ])
  _iam_bindings_add = flatten([
    for member, data in local._iam_bindings : [
      for role in data.additive : {
        member = member
        role   = role
      }
    ]
  ])
  drs_domains = concat(
    var.organization.customer_id == null ? [] : [var.organization.customer_id],
    var.org_policies_config.constraints.allowed_policy_member_domains
  )
  drs_tag_name = "${var.organization.id}/${var.org_policies_config.tag_name}"

  # intermediate values before we merge in what comes from the checklist
  _iam_principals = {
    for k, v in local.iam_principal_bindings : k => v.authoritative
  }
  _iam = merge(
    {
      for r in local.iam_delete_roles : r => []
    },
    {
      for b in local._iam_bindings_auth : b.role => b.member...
    }
  )
  _iam_bindings_additive = {
    for b in local._iam_bindings_add : "${b.role}-${b.member}" => {
      member = b.member
      role   = b.role
    }
  }
  # final values combining all sources
  iam_principals        = local._iam_principals
  iam                   = local._iam
  iam_bindings_additive = local._iam_bindings_additive
}

# import org policy constraints enabled by default in new orgs since February 2024
import {
  for_each = (
    !var.org_policies_config.import_defaults || var.bootstrap_user != null
    ? toset([])
    : toset([
      "compute.requireOsLogin",
      "compute.skipDefaultNetworkCreation",
      "compute.vmExternalIpAccess",
      "iam.allowedPolicyMemberDomains",
      "iam.automaticIamGrantsForDefaultServiceAccounts",
      "iam.disableServiceAccountKeyCreation",
      "iam.disableServiceAccountKeyUpload",
      "sql.restrictAuthorizedNetworks",
      "sql.restrictPublicIp",
      "storage.uniformBucketLevelAccess",
      "essentialcontacts.allowedContactDomains",
      "compute.setNewProjectDefaultToZonalDNSOnly",
      "compute.restrictProtocolForwardingCreationForTypes"
    ])
  )
  id = "organizations/${var.organization.id}/policies/${each.key}"
  to = module.organization.google_org_policy_policy.default[each.key]
}

module "organization" {
  source          = "../modules/organization"
  organization_id = "organizations/${var.organization.id}"
  # human (groups) IAM bindings
  iam_by_principals = {
    for k, v in local.iam_principals :
    k => distinct(concat(v, lookup(var.iam_by_principals, k, [])))
  }
  # machine (service accounts) IAM bindings
  iam = merge(
    {
      for k, v in local.iam : k => distinct(concat(v, lookup(var.iam, k, [])))
    },
    {
      for k, v in var.iam : k => v if lookup(local.iam, k, null) == null
    }
  )
  # additive bindings, used for roles co-managed by different stages
  iam_bindings_additive = merge(
    local.iam_bindings_additive,
    var.iam_bindings_additive
  )
  # delegated role grant for resource manager service account
  iam_bindings = merge(
    {
      organization_iam_admin_conditional = {
        members = [module.automation-tf-resman-sa.iam_email]
        role    = module.organization.custom_role_id["organization_iam_admin"]
        condition = {
          expression = format(
            "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
            join(",", formatlist("'%s'", [
              "roles/accesscontextmanager.policyAdmin",
              "roles/cloudasset.viewer",
              "roles/compute.orgFirewallPolicyAdmin",
              "roles/compute.xpnAdmin",
              "roles/orgpolicy.policyAdmin",
              "roles/orgpolicy.policyViewer",
              "roles/resourcemanager.organizationViewer",
              module.organization.custom_role_id["tenant_network_admin"]
            ]))
          )
          title       = "automation_sa_delegated_grants"
          description = "Automation service account delegated grants."
        }
      }
    },
    local.billing_mode != "org" ? {} : {
      organization_billing_conditional = {
        members = [module.automation-tf-resman-sa.iam_email]
        role    = module.organization.custom_role_id["organization_iam_admin"]
        condition = {
          expression = format(
            "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly([%s])",
            join(",", formatlist("'%s'", [
              "roles/billing.admin",
              "roles/billing.costsManager",
              "roles/billing.user",
            ]))
          )
          title       = "automation_sa_delegated_grants"
          description = "Automation service account delegated grants."
        }
      }
    }
  )
  custom_roles = var.custom_roles
  factories_config = {
    custom_roles = "${var.factories_config.data_dir}/custom-roles"
    org_policies = (
      var.bootstrap_user != null ? null : "${var.factories_config.data_dir}/org-policies/org"
    )
  }
  org_policies = var.bootstrap_user != null ? {} : {
    "iam.allowedPolicyMemberDomains" = {
      rules = [
        {
          allow = { values = local.drs_domains }
          condition = {
            expression = (
              "!resource.matchTag('${local.drs_tag_name}', 'allowed-policy-member-domains-all')"
            )
          }
        },
        {
          allow = { all = true }
          condition = {
            expression = (
              "resource.matchTag('${local.drs_tag_name}', 'allowed-policy-member-domains-all')"
            )
            title = "allow-all"
          }
        },
      ]
    }
  }
  tags = {
    (var.org_policies_config.tag_name) = {
      description = "Organization policy conditions."
      iam         = {}
      values = merge(
        {
          allowed-policy-member-domains-all = {}
        },
        var.org_policies_config.tag_values
      )
    }
  }
}
