locals {
  dns_files = {
    for subunit_key, subunit_value in local.int_subunits : subunit_key => fileset(
      "${var.factories_config.data_dir}/factories/${subunit_value.unit}/${subunit_key}/${local.env}/dns",
      "*.yaml"
    )
  }
  yaml_data = {
    for subunit_key, subunit_value in local.int_subunits : subunit_key => flatten([
      for file in local.dns_files[subunit_key] : yamldecode(
        file("${var.factories_config.data_dir}/factories/${subunit_value.unit}/${subunit_key}/${local.env}//dns/${file}")
      )
    ])
  }

  dns_zone_data = {
    for yaml_file in flatten([
      for subunit_key, yaml_files in local.yaml_data :
      [
        for yaml_file in yaml_files :
        {
          subunit_key = subunit_key
          name        = yaml_file.name
          domain      = yaml_file.domain
          recordsets  = yaml_file.recordsets
        }
      ]
    ]) : "${yaml_file.subunit_key}-${yaml_file.name}" => yaml_file
  }
}

module "subunit-private-zones" {
  source     = "../modules/dns"
  for_each   = local.dns_zone_data
  name       = each.value.name
  project_id = module.subunit-vpc["${each.value.subunit_key}-${local.env}"].project_id
  zone_config = {
    domain = each.value.domain
    private = {
      client_networks = [module.subunit-vpc["${each.value.subunit_key}-${local.env}"].self_link]
    }
  }

  recordsets = each.value.recordsets
}