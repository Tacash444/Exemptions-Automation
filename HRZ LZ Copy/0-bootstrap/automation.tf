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

# tfdoc:file:description Automation project and resources.

module "automation-project" {
  source          = "../modules/project"
  billing_account = var.billing_accounts[var.global_billing.account].id
  name            = "iac-core-0"
  parent = module.global-iac-folder.id
  prefix        = local.prefix
  contacts = (
    var.bootstrap_user != null || var.essential_contacts == null
    ? {}
    : { (var.essential_contacts) = ["ALL"] }
  )
  labels = var.shared_labels
  # human (groups) IAM bindings
  iam_by_principals = {
    (local.principals.gcp-devops) = [
      # "roles/iam.serviceAccountAdmin", added to additive
      "roles/iam.serviceAccountTokenCreator",
    ]
    (local.principals.gcp-organization-admins) = [
      "roles/iam.serviceAccountTokenCreator",
      "roles/iam.workloadIdentityPoolAdmin",
    ]
  }
  # machine (service accounts) IAM bindings
  iam = {
    "roles/owner" = [
      module.automation-tf-bootstrap-sa.iam_email
    ]
    "roles/cloudbuild.builds.editor" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/iam.workloadIdentityPoolAdmin" = [
      module.automation-tf-resman-sa.iam_email
    ]
    "roles/source.admin" = [
      module.automation-tf-resman-sa.iam_email
    ]
  }
  iam_bindings = {
    delegated_grants_resman = {
      members = [module.automation-tf-resman-sa.iam_email]
      role    = "roles/resourcemanager.projectIamAdmin"
      condition = {
        title       = "resman_delegated_grant"
        description = "Resource manager service account delegated grant."
        expression = format(
          "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', []).hasOnly(['%s'])",
          "roles/serviceusage.serviceUsageConsumer"
        )
      }
    }
  }
  iam_bindings_additive = {
    serviceusage_resman = {
      member = module.automation-tf-resman-sa.iam_email
      role   = "roles/serviceusage.serviceUsageConsumer"
    }
    storageadmin_resman = {
      member = module.automation-tf-resman-sa.iam_email
      role   = "roles/storage.admin"
    }
    serviceaccountadmin_resman = {
      member = module.automation-tf-resman-sa.iam_email
      role   = "roles/iam.serviceAccountAdmin"
    }
    serviceaccountadmin_devopsgroup = {
      member = (local.principals.gcp-devops)
      role   = "roles/iam.serviceAccountAdmin"
    }
  }
  org_policies = var.bootstrap_user != null ? {} : {
    "compute.skipDefaultNetworkCreation" = {
      rules = [{ enforce = true }]
    }
    "iam.automaticIamGrantsForDefaultServiceAccounts" = {
      rules = [{ enforce = true }]
    }
    "iam.disableServiceAccountKeyCreation" = {
      rules = [{ enforce = true }]
    }
  }
  services = concat(
    [
      "accesscontextmanager.googleapis.com",
      "bigquery.googleapis.com",
      "bigqueryreservation.googleapis.com",
      "bigquerystorage.googleapis.com",
      "billingbudgets.googleapis.com",
      "cloudasset.googleapis.com",
      "cloudbilling.googleapis.com",
      "cloudkms.googleapis.com",
      "cloudquotas.googleapis.com",
      "cloudresourcemanager.googleapis.com",
      "essentialcontacts.googleapis.com",
      "iam.googleapis.com",
      "iamcredentials.googleapis.com",
      "orgpolicy.googleapis.com",
      "pubsub.googleapis.com",
      "servicenetworking.googleapis.com",
      "serviceusage.googleapis.com",
      # "sourcerepo.googleapis.com",
      "stackdriver.googleapis.com",
      "storage-component.googleapis.com",
      "storage.googleapis.com",
      "sts.googleapis.com"
    ],
    # enable specific service only after org policies have been applied
    var.bootstrap_user != null ? [] : [
      "cloudbuild.googleapis.com",
      "compute.googleapis.com",
      "container.googleapis.com",
    ]
  )
}

# this stage's bucket and service account

module "automation-tf-bootstrap-gcs" {
  source     = "../modules/gcs"
  project_id = module.automation-project.project_id
  name       = "bootstrap-0"
  prefix     = local.prefix
  location   = var.locations.gcs
  iam = {
    "roles/storage.objectAdmin" = [module.automation-tf-bootstrap-sa.iam_email]
  }
  storage_class = local.gcs_storage_class
  versioning    = true
  depends_on    = [module.organization]
}

module "automation-tf-bootstrap-sa" {
  source       = "../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = "bootstrap-0"
  display_name = "Terraform organization bootstrap service account."
  prefix       = local.prefix
  # allow SA used by CI/CD workflow to impersonate this SA
  iam = {
    "roles/iam.serviceAccountTokenCreator" = compact([
      module.cicd-tf-wif-sa.iam_email,
      local.principals.gcp-organization-admins,
      var.tf_apply_auto_sa,
      # "user:${var.bootstrap_user}"
    ])
  }
}

# resource hierarchy stage's bucket and service account

module "automation-tf-resman-gcs" {
  source        = "../modules/gcs"
  project_id    = module.automation-project.project_id
  name          = "resman-0"
  prefix        = local.prefix
  location      = var.locations.gcs
  storage_class = local.gcs_storage_class
  versioning    = true
  iam = {
    "roles/storage.objectAdmin" = [module.automation-tf-resman-sa.iam_email]
  }
  depends_on = [module.organization]
}

module "automation-tf-resman-sa" {
  source       = "../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = "resman-0"
  display_name = "Terraform stage 1 resman service account."
  prefix       = local.prefix
  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      module.cicd-tf-wif-sa.iam_email,
      local.principals.gcp-organization-admins,
      var.tf_apply_auto_sa
      # "user:${var.bootstrap_user}"
    ]
  }
}
