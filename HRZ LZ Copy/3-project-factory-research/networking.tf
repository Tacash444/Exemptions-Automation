locals {
  network_admin_group = "group:${var.prefix}-${substr(var.subunits[var.factories_config.subunit].unit, 0, 6)}-${var.factories_config.subunit}-${substr(local.environment, 0, 3)}-${var.factories_config.workload}-net-admins@${var.organization.domain}"
  files_path          = "${var.factories_config.net_data_path}/default-apis"
  dns_files = flatten(
    [for default_file in fileset(local.files_path, "*.yaml") :
  "${local.files_path}/${default_file}"])

  yaml_data = flatten([
    for file in local.dns_files : yamldecode(
      file("${file}")
    )
  ])

  dns_zone_data = {
    for yaml_file in local.yaml_data : yaml_file.name =>
    {
      name         = yaml_file.name
      domain       = yaml_file.domain
      recordsets   = yaml_file.recordsets
    }
  }
}

module "workload-net-project" {
  source          = "../modules/project"
  billing_account = local.projects[keys(local.projects)[0]].billing_account
  name            = "${var.factories_config.workload}-net-0"
  parent          = module.workload-folder.id
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
  iam = {
    "roles/dns.admin"                      = [local.network_admin_group]
    "roles/compute.orgFirewallPolicyAdmin" = [local.network_admin_group]
  }
  iam_bindings_additive = {
    admin_net_user = {
      role   = "roles/compute.networkUser"
      member = local.network_admin_group
    }
    admin_viewer = {
      role   = "roles/viewer"
      member = local.network_admin_group
    }
  }
  org_policies = {
    "compute.restrictVpcPeering" = {
      rules = [{ allow = { all = true } }]
    }
  }
  factories_config = {
    org_policies = "${var.factories_config.net_data_path}/factories/${var.subunits[var.factories_config.subunit].unit}/${var.factories_config.subunit}/${local.environment}/${var.factories_config.workload}/org-policies"
  }

  vpc_sc = {
    perimeter_name = var.vpc_sc["${var.factories_config.workload}_${local.environment}"]
  }
}

module "workload-vpc" {
  source     = "../modules/net-vpc"
  project_id = module.workload-net-project.id
  name       = "${var.factories_config.workload}-0"
  mtu        = 1500

  routes = {
    to-swp = {
      dest_range    = "0.0.0.0/0"
      next_hop      = var.swp_ip
      next_hop_type = "ilb"
      priority      = 1000
      tags          = ["allow-internet", "tst-swp"]
    }
  }

  psa_configs = [{
    ranges = {
      "default-psa" = "192.168.0.0/24"
    }
    export_routes = true
    import_routes = true
  }]
  factories_config = {
    subnets_folder = "${var.factories_config.net_data_path}/factories/${var.subunits[var.factories_config.subunit].unit}/${var.factories_config.subunit}/${local.environment}/${var.factories_config.workload}/subnets"
  }
  delete_default_routes_on_create = true
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "peering-workload-to-global" {
  source        = "../modules/net-vpc-peering"
  local_network = module.workload-vpc.self_link
  peer_network  = var.global_vpc
  routes_config = {
    local = { export = false }
    peer  = { import = false }
  }
}

module "workload-firewall-policy" {
  source    = "../modules/net-firewall-policy"
  name      = "${var.factories_config.workload}-firewall-policy"
  parent_id = module.workload-net-project.id
  region    = "global"
  attachments = {
    subunit-vpc = module.workload-vpc.self_link
  }
}

module "default-private-zone" {
  source     = "../modules/dns"
  for_each   = local.dns_zone_data
  name       = each.value.name
  project_id = module.workload-vpc.project_id
  zone_config = {
    domain = each.value.domain
    private = {
      client_networks = [module.workload-vpc.self_link]
    }
  }

  recordsets = each.value.recordsets
}
