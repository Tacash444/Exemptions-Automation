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

# tfdoc:file:description Organization-level IAM bindings locals.

locals {
  # IAM roles in the org to reset (remove principals)
  iam_delete_roles = [
    "roles/billing.creator"
  ]
  # domain IAM bindings
  iam_domain_bindings = var.organization.domain == null ? {} : {
    "domain:${var.organization.domain}" = {
      authoritative = []
      additive      = ["roles/browser"]
    }
  }
  # human (groups) IAM bindings
  iam_principal_bindings = {
    # (local.principals.gcp-billing-admins) = {
    #   authoritative = []
    #   additive = (
    #     local.billing_mode != "org" ? [] : [
    #       "roles/billing.admin"
    #     ]
    #   )
    # }
    # (local.principals.gcp-network-admins) = {
    #   authoritative = [
    #     "roles/cloudasset.owner",
    #     "roles/cloudsupport.techSupportEditor",
    #   ]
    #   additive = [
    #     "roles/compute.orgFirewallPolicyAdmin",
    #     "roles/compute.xpnAdmin"
    #   ]
    # }
    (local.principals.gcp-organization-admins) = {
      authoritative = [
        "roles/cloudasset.owner",
        "roles/cloudsupport.admin",
        "roles/compute.osAdminLogin",
        "roles/compute.osLoginExternalUser",
        "roles/owner",
        "roles/resourcemanager.organizationAdmin",
        "roles/resourcemanager.tagAdmin",
        "roles/iam.workforcePoolAdmin"
      ]
      additive = concat(
        [
          "roles/orgpolicy.policyAdmin",
          "roles/resourcemanager.folderAdmin",
          "roles/resourcemanager.projectCreator"
        ],
        local.billing_mode != "org" ? [] : [
          "roles/billing.admin"
        ]
      )
    }
    (local.principals.gcp-security-admins) = {
      authoritative = [
        "roles/cloudasset.owner",
        "roles/cloudsupport.techSupportEditor",
        "roles/iam.securityReviewer",
        "roles/logging.admin",
        "roles/securitycenter.admin",
      ]
      additive = [
        "roles/viewer",
        "roles/securitycenter.adminEditor"
        #   "roles/accesscontextmanager.policyAdmin",
        #   "roles/iam.organizationRoleAdmin",
      ]
    }
    # # gcp-security-soc
    # (local.principals.gcp-security-soc) = {
    #   authoritative = []
    #   additive = [
    #     "roles/viewer"
    #   ]
    # }
    # (local.principals.gcp-support) = {
    #   authoritative = [
    #     "roles/cloudsupport.techSupportEditor",
    #     "roles/logging.viewer",
    #     "roles/monitoring.viewer",
    #   ]
    #   additive = []
    # }
    (local.principals.gcp-mamram-sa) = {
      authoritative = []
      additive = [
        "roles/viewer",
        "roles/resourcemanager.folderViewer"
      ]
    }
    # (local.principals.gcp-finops-admins) = {
    #   authoritative = [
    #   ]
    #   additive = [
    #     "roles/viewer",
    #     "roles/commerceorggovernance.admin"
    #   ]
    # }
  }
  # machine (service accounts) IAM bindings, in logical format
  # the service account module's "magic" outputs allow us to use dynamic values
  iam_sa_bindings = {
    (module.automation-tf-bootstrap-sa.iam_email) = {
      authoritative = [
        "roles/essentialcontacts.admin",
        "roles/logging.admin",
        "roles/resourcemanager.organizationAdmin",
        "roles/resourcemanager.projectMover",
        "roles/resourcemanager.tagAdmin"
      ]
      additive = concat(
        [
          "roles/iam.organizationRoleAdmin",
          "roles/orgpolicy.policyAdmin",
          "roles/resourcemanager.projectCreator"
        ],
        local.billing_mode != "org" ? [] : [
          "roles/billing.admin"
        ]
      )
    }
    (module.automation-tf-resman-sa.iam_email) = {
      authoritative = [
        "roles/logging.admin",
        "roles/resourcemanager.tagAdmin",
        "roles/resourcemanager.tagUser",
        "roles/owner"
      ]
      additive = concat(
        [
          "roles/resourcemanager.folderAdmin",
          "roles/orgpolicy.policyAdmin",
          "roles/iam.securityAdmin",
          "roles/resourcemanager.projectCreator",
          "roles/iam.serviceAccountAdmin"
        ],
        local.billing_mode != "org" ? [] : [
          "roles/billing.admin"
        ]
      )
    }
  }
  # bootstrap user bindings
  iam_user_bootstrap_bindings = var.bootstrap_user == null ? {} : {
    "user:${var.bootstrap_user}" = {
      authoritative = [
        "roles/logging.admin",
        "roles/owner",
        "roles/resourcemanager.organizationAdmin",
        # "roles/resourcemanager.projectCreator",
        "roles/resourcemanager.tagAdmin"
      ]
      # TODO: align additive roles with the README
      additive = flatten([
        local.billing_mode != "org" ? [] : [
          "roles/billing.admin"
        ], 
        [
        # "roles/logging.admin",
        # "roles/owner",
        # "roles/resourcemanager.organizationAdmin",
        "roles/resourcemanager.projectCreator",
        # "roles/resourcemanager.tagAdmin"
        ]]
      )
    }
  }
}
