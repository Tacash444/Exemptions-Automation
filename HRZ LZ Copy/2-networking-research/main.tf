locals {
  env = "research"
  service_accounts = {
    for k, v in coalesce(var.service_accounts, {}) :
    k => "serviceAccount:${v}" if v != null
  }

  network_admin_groups = {
    for work, sub in var.research_workloads: work => "group:${var.prefix}-${substr(var.subunits[sub].unit, 0, 6)}-${sub}-${substr(local.env, 0, 3)}-${work}-net-admins@${var.organization.domain}"
  }

  research_workloads = merge([
    for sub_key, sub_value in var.subunits :
    { for workload in distinct([for f in fileset("${var.factories_config.projects_dir}/${sub_key}/research", "**/*.yaml") : dirname(f)]) :
    workload => sub_key }
  ]...)
}

module "firewall-policy-default" {
  source    = "../modules/net-firewall-policy"
  name      = "hierarchical-firewall-policy-0"
  parent_id = "organizations/${var.organization.id}"
  factories_config = { cidr_file_path = "${var.factories_config.data_dir}/cidrs.yaml"
  ingress_rules_file_path = "${var.factories_config.data_dir}/hierarchical-ingress-rules.yaml"
  egress_rules_file_path = "${var.factories_config.data_dir}/hierarchical-egress-rules.yaml" }
}

