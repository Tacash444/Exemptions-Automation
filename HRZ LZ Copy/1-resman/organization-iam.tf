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

# tfdoc:file:description Organization-level IAM bindings locals.

locals {
  iam_bindings_additive = merge(
    # network and security
    {
      sa_sec_org_policy_admin = {
        member = module.branch-security-sa.iam_email
        role   = "roles/orgpolicy.policyAdmin"
      }
      sa_sec_asset_viewer = {
        member = module.branch-security-sa.iam_email
        role   = "roles/cloudasset.viewer"
      }
      sa_sec_project_creator = {
        member = module.branch-security-sa.iam_email
        role   = "roles/resourcemanager.projectCreator"
      }
      sa_sec_vpcsc_admin = {
        member = module.branch-security-sa.iam_email
        role   = "roles/accesscontextmanager.policyAdmin"
      }
      sa_aut_sec_admin = {
        member = module.branch-automations-sa.iam_email
        role   = "roles/iam.securityAdmin"
      },
      sa_shared_projects_org_viewer = {
        member = module.branch-shared-projects-sa.iam_email
        role = "roles/viewer"
      }
      sa_shared_projects_org_vpc_sc_admin = {
        member = module.branch-shared-projects-sa.iam_email
        role = "roles/accesscontextmanager.policyAdmin"
      }
      sa_shared_projects_org_billing_admin = {
        member = module.branch-shared-projects-sa.iam_email
        role = "roles/billing.admin"
      }
      sa_shared_projects_org_policy_admin = {
        member = module.branch-shared-projects-sa.iam_email
        role = "roles/orgpolicy.policyAdmin"
      }
    },
    # scoped org policy admin grants for project factory
    {
      for k, v in toset(local.pf-states) :
      "sa_pf_${k}_org_policy_admin" => {
        member = module.pf-sas[k].iam_email
        role   = "roles/orgpolicy.policyAdmin"
      }
    },
    # VPC-SC admin grants for project factory - should this be somehow limited by perimeters?
    {
      for k, v in module.pf-sas :
      "sa_pf_${k}_org_vpc_sc_admin" => {
        member    = v.iam_email
        role      = "roles/accesscontextmanager.policyAdmin"
        condition = null
      }
    },
    {
      for k, v in module.branch-env-network-sa :
      "sa_net_${k}_org_policy_admin" => {
        member    = v.iam_email
        role      = "roles/accesscontextmanager.policyAdmin"
        condition = null
      }
    },
    {
      for k, v in module.pf-sas :
      "sa_pf_${k}_org_viewer" => {
        member    = v.iam_email
        role      = "roles/viewer"
        condition = null
      }
    },
    {
      for k, v in module.pf-sas :
      "sa_pf_${k}_org_billing_admin" => {
        member    = v.iam_email
        role      = "roles/billing.admin"
        condition = null
      }
    },
    contains(keys(local.sa_principals), "finops_auto_sa") ? {
      sa_finops_compute_auto_admin = {
        member = local.sa_principals["finops_auto_sa"]
        role   = var.custom_roles.finops_compute_auto_admin
      }

    } : {},
    contains(keys(local.sa_principals), "finops_delete_disks_auto_sa") ? {
      sa_finops_delete_disks = {
        member = local.sa_principals["finops_delete_disks_auto_sa"]
        role   = "roles/resourcemanager.folderViewer"
      }

    } : {},
    contains(keys(local.sa_principals), "finops_delete_disks_auto_sa") ? {
      sa_finops_delete_disks_second_role = {
        member = local.sa_principals["finops_delete_disks_auto_sa"]
        role   = var.custom_roles.finops_delete_unused_disks
      }

    } : {},
    contains(keys(local.sa_principals), "auto_tiering_storage_sa") ? {
      auto_tiering_storage_sa_storage_view = {
        member = local.sa_principals["auto_tiering_storage_sa"]
        role   = var.custom_roles.storage_viewer
      }

    } : {},

    contains(keys(local.sa_principals), "auto_tiering_storage_sa") ? {
      auto_tiering_storage_sa_resman_view = {
        member = local.sa_principals["auto_tiering_storage_sa"]
        role   = "roles/browser"
      }

    } : {},
    {
      for sa_iam in local._envs_iam_sa : "sa_net_${sa_iam}_org_policy_admin" => {
        member = sa_iam
        role   = "roles/orgpolicy.policyAdmin"
      }
    },
    {
      for sa_iam in local._envs_iam_sa : "sa_net_${sa_iam}_fw_policy_admin" => {
        member = sa_iam
        role   = "roles/compute.orgFirewallPolicyAdmin"
      }
    }
  )
}
