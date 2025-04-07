# module "workload-net-project" {
#   source          = "../modules/project"
#   for_each        = local.research_workloads
#   billing_account = var.subunits[each.value].billing_account.id
#   name            = "${each.key}-net-0"
#   parent          = var.subunits[each.value].folder_ids["${each.value}/${local.env}/${each.key}"]
#   prefix          = var.prefix
#   services = [
#     "container.googleapis.com",
#     "compute.googleapis.com",
#     "dns.googleapis.com",
#     "iap.googleapis.com",
#     "networkmanagement.googleapis.com",
#     "servicenetworking.googleapis.com",
#     "stackdriver.googleapis.com",
#     "vpcaccess.googleapis.com",
#     "cloudbuild.googleapis.com"
#   ]

#   shared_vpc_host_config = {
#     enabled = true
#   }
#   iam = {
#     "roles/dns.admin" = compact([
#       try(local.service_accounts.project-factory-prod, null),
#       local.network_admin_groups[each.key]
#     ])
#     "roles/compute.orgFirewallPolicyAdmin" = [local.network_admin_groups[each.key]]
#   }
#   iam_bindings_additive = {
#     admin_net_user = {
#       role   = "roles/compute.networkUser"
#       member = local.network_admin_groups[each.key]
#     }
#     admin_viewer = {
#       role   = "roles/viewer"
#       member = local.network_admin_groups[each.key]
#     }
#   }
#   iam_bindings = {
#     sa_delegated_grants = {
#       role = "roles/resourcemanager.projectIamAdmin"
#       members = compact([
#         try(local.service_accounts.project-factory-prod, null),
#       ])
#     }
#   }
#   org_policies = {
#     "compute.restrictVpcPeering" = {
#       rules = [{ allow = { all = true } }]
#     }
#   }
#   factories_config = {
#     org_policies = "${var.factories_config.data_dir}/factories/${var.subunits[each.value].unit}/${each.value}/${local.env}/${each.key}/org-policies"
#   }

#   vpc_sc = {
#     perimeter_name = var.vpc_sc["${each.key}_${local.env}"]
#   }
# }

# module "workload-vpc" {
#   source     = "../modules/net-vpc"
#   for_each   = local.research_workloads
#   project_id = module.workload-net-project[each.key].id
#   name       = "${each.key}-0"
#   mtu        = 1500

#   routes = {
#     to-swp = {
#       dest_range    = "0.0.0.0/0"
#       next_hop      = local.swp_ip
#       next_hop_type = "ilb"
#       priority      = 1000
#       tags          = ["allow-internet", "tst-swp"]
#     }
#   }

#   psa_configs = [{
#     ranges = {
#       "default-psa" = "192.168.0.0/24"
#     }
#     export_routes = true
#     import_routes = true
#   }]
#   factories_config = {
#     subnets_folder = "${var.factories_config.data_dir}/factories/${var.subunits[each.value].unit}/${each.value}/${local.env}/${each.key}/subnets"
#   }
#   delete_default_routes_on_create = true
#   create_googleapis_routes = {
#     private    = true
#     restricted = true
#   }
# }

# module "peering-workload-to-global" {
#   source        = "../modules/net-vpc-peering"
#   for_each      = local.research_workloads
#   local_network = module.workload-vpc[each.key].self_link
#   peer_network  = module.research-vpc.self_link
#   routes_config = {
#     local = { export = false }
#     peer  = { import = false }
#   }
# }

# module "workload-firewall-policy" {
#   source    = "../modules/net-firewall-policy"
#   for_each  = local.research_workloads
#   name      = "${each.key}-firewall-policy"
#   parent_id = module.workload-net-project[each.key].id
#   region    = "global"
#   attachments = {
#     subunit-vpc = module.workload-vpc[each.key].self_link
#   }
# }
