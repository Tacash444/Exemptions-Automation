locals {
  env = "integration"
  int_subunits = { for subunit_key, subunit_value in var.integration_subunits : lower("${subunit_key}-${local.env}") => {
    division = subunit_value.division
    env      = local.env
    unit     = subunit_value.unit
    subunit  = subunit_key
    id       = lower("${substr(subunit_key, 0, 6)}-${substr(local.env, 0, 3)}")
    }
  }

}
