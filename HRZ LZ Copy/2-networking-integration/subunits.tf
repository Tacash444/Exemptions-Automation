module "subunit-networking-folder" {
  source   = "../modules/folder"
  for_each = local.int_subunits
  parent   = var.integration_subunits[each.value.subunit].folder_ids["${each.value.subunit}/${local.env}/services/"]
  #   iam = {
  #     "roles/resourcemanager.projectCreator" = try([module.pf-sas[each.key].iam_email], [])
  #     "roles/resourcemanager.projectDeleter" = try([module.pf-sas[each.key].iam_email], [])
  #     "roles/resourcemanager.folderAdmin"    = try([module.pf-sas[each.key].iam_email], [])
  #     "roles/owner"                          = try([module.pf-sas[each.key].iam_email], [])
  #     "roles/compute.xpnAdmin"               = try([module.pf-sas[each.key].iam_email], [])
  #   }
  name = "Network"
  iam_by_principals = {
    (var.groups.gcp-network-admins) = [
      "roles/editor",
    ]
  }
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/factories/${each.value.unit}/${each.value.subunit}/${local.env}/org-policies"
  }
}

module "subunit-net-project" {
  source          = "../modules/project"
  for_each        = local.int_subunits
  billing_account = var.integration_subunits[each.value.subunit].billing_account.id
  name            = "${each.value.id}-net-0"
  parent          = module.subunit-networking-folder[each.key].folder.id
  prefix          = var.prefix
  services = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "vpcaccess.googleapis.com",
    "cloudbuild.googleapis.com"
  ]

  shared_vpc_host_config = {
    enabled = true
  }

  vpc_sc = {
    perimeter_name = var.vpc_sc["${each.value.unit}_${local.env}"]
  }
}

module "subunit-vpc" {
  source     = "../modules/net-vpc"
  for_each   = local.int_subunits
  project_id = module.subunit-net-project[each.key].id
  name       = "${each.key}-0"
  mtu        = 1500
  psa_configs = [{
    ranges = {
      "default-psa" = "192.168.0.0/24"
    }
    export_routes = true
    import_routes = true
  }]
  factories_config = {
    subnets_folder = "${var.factories_config.data_dir}/factories/${each.value.unit}/${each.value.subunit}/${local.env}/subnets"
  }
  delete_default_routes_on_create = true
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "subunit-firewall-policy" {
  source    = "../modules/net-firewall-policy"
  for_each  = local.int_subunits
  name      = "${each.key}-firewall-policy"
  parent_id = module.subunit-net-project[each.key].id
  region    = "global"
  attachments = {
    subunit-vpc = module.subunit-vpc[each.key].self_link
  }
  egress_rules = {
    for k, v in module.subunit-vpc[each.key].subnets : "east-west-egress-${split("/", k)[1]}" => {
      priority = 5000 + index(values(module.subunit-vpc[each.key].subnets), v)
      match = {
        destination_ranges = [v.ip_cidr_range]
        source_ranges      = [v.ip_cidr_range]
      }
      action = "allow"
    }
  }

  ingress_rules = {
    for k, v in module.subunit-vpc[each.key].subnets : "east-west-ingress-${split("/", k)[1]}" => {
      priority = 5100 + index(values(module.subunit-vpc[each.key].subnets), v)
      match = {
        destination_ranges = [v.ip_cidr_range]
        source_ranges      = [v.ip_cidr_range]
      }
      action = "allow"
    }
  }

  factories_config = {
    egress_rules_file_path  = "${var.factories_config.data_dir}/factories/${each.value.unit}/${each.value.subunit}/${local.env}/fw-rules/egress.yaml"
    ingress_rules_file_path = "${var.factories_config.data_dir}/factories/${each.value.unit}/${each.value.subunit}/${local.env}/fw-rules/ingress.yaml"
  }
}

module "subunit-nat" {
  source         = "../modules/net-cloudnat"
  for_each       = local.int_subunits
  project_id     = module.subunit-net-project[each.key].project_id
  router_network = module.subunit-vpc[each.key].name
  router_name    = "${each.key}-router"
  region         = var.region
  name           = "${each.key}-nat"
  config_port_allocation = {
    enable_endpoint_independent_mapping = false
    enable_dynamic_port_allocation      = true
  }
}
