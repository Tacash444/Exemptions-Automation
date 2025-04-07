locals {
  _shared_projects_path = var.factories_config.projects_data_path
  _shared_projects = merge(
    {
      for f in try(fileset(local._shared_projects_path, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => merge(
        yamldecode(file("${local._shared_projects_path}/${f}"))
      )
    },
  )
  # folders = {
  #   for k, v in local._shared_projects : k => merge(
  #     v,
  #     try(v.folder_config, {}),
  #     {
  #       name = v.name
  #     }
  #   )
  # }
  projects = {
    for project_name, project in local._shared_projects :
    project_name => merge(
      project,
      {
        name            = project.name
        billing_account = lookup(project, "billing_account_id", var.billing_accounts[var.global_billing.account].id)
        parent          = var.folder_ids[project.folder]
        prefix          = var.prefix
        budget          = lookup(project, "budget", null)
      }
    )
  }
}
