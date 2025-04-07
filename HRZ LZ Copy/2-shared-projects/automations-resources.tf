resource "google_iam_workload_identity_pool" "shared-automations" {
  project                   = module.projects["automations"].project_id
  workload_identity_pool_id = "shared-auto-github-pool-0"
}

resource "google_iam_workload_identity_pool_provider" "shared-automations" {
  project = module.projects["automations"].project_id
  workload_identity_pool_id = (
    google_iam_workload_identity_pool.shared-automations.workload_identity_pool_id
  )
  workload_identity_pool_provider_id = "shared-auto-github-provider-0"
  attribute_condition = "assertion.repository=='${var.shared_auto_github.org}/${var.shared_auto_github.repo}'"
  attribute_mapping                  = var.automation.identity_providers_defs.github.attribute_mapping
  oidc {
    issuer_uri = var.automation.identity_providers_defs.github.issuer_uri
  }
}
