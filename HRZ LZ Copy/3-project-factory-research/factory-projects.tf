locals {
  gcs_storage_class = (
    length(split("-", var.locations.gcs)) < 2
    ? "MULTI_REGIONAL"
    : "REGIONAL"
  )

  environment    = "research"
  workload_path  = "${var.factories_config.subunit}/${local.environment}/${var.factories_config.workload}"
  _projects_path = "${var.factories_config.projects_data_path_prefix}/${local.workload_path}"
  _projects_raw = merge(
    {
      for f in try(fileset(local._projects_path, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => merge(
        yamldecode(file("${local._projects_path}/${f}"))
      )
    },
  )

  projects = {
    for app_name, app in local._projects_raw :
    app_name => merge(
      app,
      {
        billing_account = lookup(app, "billing_account_id", var.subunits[var.factories_config.subunit].billing_account.id)
      }
  ) }

  default_services = [
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "container.googleapis.com",
    "osconfig.googleapis.com"
  ]

  default_robots_iam = {
    "roles/cloudbuild.workerPoolUser" : ["cloudbuild-sa"],
    "roles/compute.networkUser" : ["cloudrun"],
    "roles/container.hostServiceAgentUser" : ["container-engine"]
  }
}
