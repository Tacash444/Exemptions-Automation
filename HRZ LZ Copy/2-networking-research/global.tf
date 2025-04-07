locals {
  swp_ip = cidrhost(module.research-vpc.subnets["${var.region}/swp-subnet"].ip_cidr_range, 3)
}


module "research-net-project" {
  source          = "../modules/project"
  billing_account = var.billing_accounts[var.global_billing.account].id
  name            = "${local.env}-global-net-0"
  parent          = var.folder_ids.networking
  prefix          = var.prefix
  labels = var.shared_labels
  services = [
    "container.googleapis.com",
    "compute.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "networkmanagement.googleapis.com",
    "servicenetworking.googleapis.com",
    "stackdriver.googleapis.com",
    "vpcaccess.googleapis.com",
    "cloudbuild.googleapis.com",
    "networksecurity.googleapis.com",
    "networkservices.googleapis.com"
  ]
  factories_config = {
    org_policies = "${var.factories_config.data_dir}/factories/global-shared/network/research/org-policies"
  }
}

module "research-vpc" {
  source     = "../modules/net-vpc"
  project_id = module.research-net-project.id
  name       = "${local.env}-net-0"
  mtu        = 1500
  routes = {
    nat-internet = {
      dest_range    = "0.0.0.0/0"
      next_hop      = "default-internet-gateway"
      next_hop_type = "gateway"
      priority      = 1000
    }
    swp-test = {
      dest_range    = "0.0.0.0/0"
      next_hop      = local.swp_ip
      next_hop_type = "ilb"
      priority      = 1000
      tags          = ["swp-test"]
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
    subnets_folder = "${var.factories_config.data_dir}/factories/global-shared/network/research/subnets"
  }
  create_googleapis_routes = {
    private    = true
    restricted = true
  }
}

module "research-firewall-policy" {
  source    = "../modules/net-firewall-policy"
  name      = "${local.env}-firewall-policy"
  parent_id = module.research-net-project.id
  region    = "global"
  attachments = {
    subunit-vpc = module.research-vpc.self_link
  }
  egress_rules = {
    "allow-all" = {
      priority = 1000
      match = {
        destination_ranges = ["0.0.0.0/0"]
      }
      action = "allow"
    }
  }
  ingress_rules = {
    "allow-all" = {
      priority = 1001
      match = {
        source_ranges = ["0.0.0.0/0"]
      }
      action = "allow"
    }
  }
}

module "secure-web-proxy" {
  source     = "../modules/net-swp"
  project_id = module.research-net-project.id
  region     = var.region
  name       = "${local.env}-swp"
  network    = module.research-vpc.id
  subnetwork = module.research-vpc.subnets["${var.region}/swp-subnet"].id
  gateway_config = {
    addresses             = [local.swp_ip]
    next_hop_routing_mode = true
    ports = [80, 443
    ]
  }

  factories_config = {
    policy_rules = "${var.factories_config.data_dir}/factories/global-shared/network/research/swp-policies"
    url_lists    = "${var.factories_config.data_dir}/factories/global-shared/network/research/swp-url-lists"
  }
}
