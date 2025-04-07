# tfdoc:file:description Workload Identity Federation provider definitions.

locals {
  identity_providers_defs = {
    # https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect
    github = {
      attribute_mapping = {
        "google.subject"             = "assertion.sub"
        "attribute.repository"       = "assertion.repository"
      }
      issuer_uri       = "https://token.actions.githubusercontent.com"
      # principal_branch = "principalSet://iam.googleapis.com/%s/attribute.fast_sub/repo:%s:ref:refs/heads/%s"
      # principal_repo   = "principalSet://iam.googleapis.com/%s/attribute.repository/%s"
    }
  }
}

resource "google_iam_workload_identity_pool" "cicd_pool" {
  project                   = module.automation-project.project_id
  workload_identity_pool_id = "${var.prefix}-identity-pool"
}

resource "google_iam_workload_identity_pool_provider" "cicd_provider" {
  project  = module.automation-project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.cicd_pool.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${var.prefix}-github-provider"
  attribute_mapping                  = local.identity_providers_defs.github.attribute_mapping
  oidc {
    issuer_uri = local.identity_providers_defs.github.issuer_uri
  }
  attribute_condition = "attribute.repository == assertion.repository"
}

module "cicd-tf-wif-sa" {
  source       = "../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = "cicd-wif-0"
  display_name = "Terraform cicd service account."
  prefix       = local.prefix

  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      "principalSet://iam.googleapis.com/projects/${module.automation-project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.cicd_pool.workload_identity_pool_id}/attribute.repository/${var.github.org}/${var.github.repo}"
    ]
  }
}

resource "google_iam_workload_identity_pool_provider" "auto_provider" {
  project  = module.automation-project.project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.cicd_pool.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "${var.prefix}-github-automations-provider"
  attribute_mapping                  = local.identity_providers_defs.github.attribute_mapping
  oidc {
    issuer_uri = local.identity_providers_defs.github.issuer_uri
  }
  attribute_condition = "attribute.repository == assertion.repository"
}

module "auto-wif-sa" {
  source       = "../modules/iam-service-account"
  project_id   = module.automation-project.project_id
  name         = "github-wif-0"
  display_name = "Terraform cicd service account."
  prefix       = local.prefix

  iam = {
    "roles/iam.serviceAccountTokenCreator" = [
      "principalSet://iam.googleapis.com/projects/${module.automation-project.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.cicd_pool.workload_identity_pool_id}/attribute.repository/${var.github.org}/automations-hrz"
    ]
  }
}