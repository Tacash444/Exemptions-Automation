locals {
  environment = "integration"
  _applications_path = "${var.factories_config.projects_data_path_prefix}/${var.factories_config.subunit}/${local.environment}"
  _applications = merge(
    {
      for f in try(fileset(local._applications_path, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => merge(
        yamldecode(file("${local._applications_path}/${f}"))
      )
    },
  )
  folders = {
    for k, v in local._applications : k => merge(
      v,
      try(v.folder_config, {}),
      {
        name = v.name
      }
    )
  }
  projects = merge(flatten([
    for app_name, app in local._applications : [
      for project_id, project in app.projects :
      {
        "${app.prefix}/${project_id}" = merge(
          project,
          {
            name            = project_id
            billing_account = lookup(project, "billing_account_id", var.subunits[var.factories_config.subunit].billing_account.id)
            parent          = module.folders[app_name].id

            # hrz-starfish-mam-int-test-1 
            prefix          = "${var.prefix}-${var.subunits[var.factories_config.subunit].unit}-${var.factories_config.subunit}-${substr(local.environment, 0, 3)}-${app.prefix}"
            budget = lookup(project, "budget", null)
          }
        )
      }
    ]
  ])...)

  default_services = [
    "run.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "container.googleapis.com"
  ]

  default_robots_iam = {
    "roles/cloudbuild.workerPoolUser" : ["cloudbuild-sa"],
    "roles/compute.networkUser" : ["cloudrun"],
    "roles/container.hostServiceAgentUser" : ["container-engine"]
  }
}
