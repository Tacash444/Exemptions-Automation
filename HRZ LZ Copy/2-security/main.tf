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

locals {
  _data_paths = {
    for k in ["egress-policies", "ingress-policies", "access-levels"] :
    k => pathexpand("${var.factories_config.data_dir}/2-security/${replace("${k}", "_", "-")}")
  }

  _data = {
    for k, v in local._data_paths : k => {
      for f in try(fileset(v, "**/*.yaml"), []) :
      trimsuffix(f, ".yaml") => yamldecode(file("${v}/${f}"))
    }
  }

  _allowed_apis_raw = {
    for f in fileset("${var.factories_config.data_dir}/2-security/allowed-apis", "*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${var.factories_config.data_dir}/2-security/allowed-apis/${f}"))
  }

  _ingress_policy_perimeters = {
    for k, v in local._data.ingress-policies :
    k => try(v.perimeters, [])
  }
  _egress_policy_perimeters = {
    for k, v in local._data.egress-policies :
    k => try(v.perimeters, [])
  }

  _access_level_perimeters = {
    for k, v in local._data.access-levels :
    k => try(v.perimeters, [])
  }

  units = distinct([
    for sub_key, sub_value in var.subunits : sub_value.unit
  ])

  _restricted_services = yamldecode(
    file("${path.module}/vpc-sc-restricted-services.yaml")
  )

  # workloads_ = {
  #   for f in fileset("${var.factories_config.data_dir}/projects/", "**/research/**/*.yaml") :
  #   "${split("/", f)[2]}_research" => distinct(concat([for per, value in yamldecode(file("${var.factories_config.data_dir}/projects/${f}")).iam_bindings_additive : value.member], [var.groups.gcp-organization-admins]))
  # }

  workloads = {
    for workload, subunit in var.research_workloads : "${workload}_research" => distinct(
      concat(flatten([
        for f in fileset("${var.factories_config.data_dir}/projects/${subunit}/research/${workload}", "**/*.yaml") :
        [for per, groups in yamldecode(file("${var.factories_config.data_dir}/projects/${subunit}/research/${workload}/${f}")).iam_bindings_additive : groups.member]
        ]
      ), distinct(values(var.groups)))
    )
  }

  data_projects = {
    for f in fileset("${var.factories_config.data_dir}/projects/", "**/data/**/*.yaml") :
    "${trimsuffix(split("/", f)[2], ".yaml")}_data" => distinct(concat([for per, groups in yamldecode(file("${var.factories_config.data_dir}/projects/${f}")).owner : groups], distinct(values(var.groups))))
  }

  projects_groups = merge(local.workloads, local.data_projects)

  exempt_tf = {
    egress = {
      org-iac-proj = {
        from = {
          identities    = [for service_account in concat(compact(values(var.service_accounts)), var.all_vpcsc_exemp) : service_account]
          identity_type = "IDENTITY_TYPE_UNSPECIFIED"
        }
        to = {
          operations = [{ service_name = "*" }]
          resources  = ["*"]
        }
      }
    }
    ingress = {
      org-iac-proj = {
        from = {
          identities    = [for service_account in concat(compact(values(var.service_accounts)), var.all_vpcsc_exemp) : service_account]
          access_levels = ["*"]
        }
        to = {
          operations = [{ service_name = "*" }]
          resources  = ["*"]
        }
      }
    }
  }

  exempt_groups = {
    ingress = {
      for project, groups in local.projects_groups : "${project}-default-apis" => {
        from = {
          identities    = groups
          access_levels = ["*"]

        }
        to = {
          operations = [for api, permissions in try(local._allowed_apis_raw[project], local._allowed_apis_raw["default"]) :
            {
              service_name     = api,
              method_selectors = permissions
            }
          ]
          resources = ["*"]
        }
      }
    }
    egress = {
      for project, groups in local.projects_groups : "${project}-default-apis" => {
        from = {
          identities    = groups
          identity_type = "IDENTITY_TYPE_UNSPECIFIED"

        }
        to = {
          operations = [for api, permissions in try(local._allowed_apis_raw[project], local._allowed_apis_raw["default"]) :
            {
              service_name     = api,
              method_selectors = permissions
            }
          ]
          resources = ["*"]
        }
      }
    }
  }


  ingress_policies = merge(local.exempt_groups.ingress, local.exempt_tf.ingress)

  egress_policies = merge(local.exempt_groups.egress, local.exempt_tf.egress)

  storage_perimeters = {
    for project, _ in local.projects_groups :
    project => {
      ingress_policies = concat(
        keys(local.exempt_tf.ingress),
        [for key in keys(local.exempt_groups.ingress) : key if strcontains(key, project)],
        [for policy_key, perimeters in local._ingress_policy_perimeters : policy_key if contains(perimeters, project)]
      )
      egress_policies = concat(
        keys(local.exempt_tf.egress),
        [for key in keys(local.exempt_groups.egress) : key if strcontains(key, project)],
        [for policy_key, perimeters in local._egress_policy_perimeters : policy_key if contains(perimeters, project)]
      )
    }
  }

  ## need to update to integration real
  integration_perimeters = {
    for unit in local.units :
    "${unit}_integration" => {
      parent = unit
      ingress_policies = concat(keys(local.exempt_tf.ingress), [
        for policy_key, perimeters in local._ingress_policy_perimeters :
        policy_key
        if contains(perimeters, unit)
      ])
      egress_policies = concat(keys(local.exempt_tf.egress), [
        for policy_key, perimeters in local._egress_policy_perimeters :
        policy_key
        if contains(perimeters, unit)
      ])
    }
  }

  global_perimeters = {
    for per in var.global_perimeters :
    per => {
      parent = per
      ingress_policies = concat(keys(local.exempt_tf.ingress), [
        for policy_key, perimeters in local._ingress_policy_perimeters :
        policy_key
        if contains(perimeters, per)
      ])
      egress_policies = concat(keys(local.exempt_tf.egress), [
        for policy_key, perimeters in local._egress_policy_perimeters :
        policy_key
        if contains(perimeters, per)
      ])
      access_levels = [
        for access_level, perimeters in local._access_level_perimeters :
        access_level
        if contains(perimeters, per)
      ]
    }
  }

  perimeters = merge(local.integration_perimeters, local.storage_perimeters, local.global_perimeters)


  vpc_sc_config = merge({
    for key, value in local.perimeters : key => {
      access_levels           = try(value.access_levels, [])
      resources               = []
      restricted_services     = local._restricted_services
      egress_policies         = value.egress_policies
      ingress_policies        = value.ingress_policies
      vpc_accessible_services = null
    }
    }
  )
}

module "vpc_sc" {
  source        = "../modules/vpc-sc"
  access_policy = null
  access_policy_create = {
    parent = "organizations/${var.organization.id}"
    title  = "vpc-sc-ap"
  }
  access_levels    = var.access_levels
  ingress_policies = local.ingress_policies
  egress_policies  = local.egress_policies

  factories_config = {
    ingress_policies = "${var.factories_config.data_dir}/2-security/ingress-policies"
    egress_policies  = "${var.factories_config.data_dir}/2-security/egress-policies"
    access_levels    = "${var.factories_config.data_dir}/2-security/access-levels"
  }

  service_perimeters_regular = {
    for k, v in local.vpc_sc_config : k => {
      spec = (
        try(var.dry_run, null) == true
        ? v
        : null
      )
      status = (
        try(var.dry_run, null) != true
        ? v
        : null
      )
      use_explicit_dry_run_spec = try(var.dry_run, null)
    }
  }
}