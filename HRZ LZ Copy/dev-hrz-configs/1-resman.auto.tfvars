outputs_location        = "../dev-hrz-configs"
environments            = ["research", "integration", "data"]
environments_networking = ["research", "integration"]


factories_config = {
  data_dir     = "../dev-hrz-configs/data/1-resman"
  projects_dir = "../dev-hrz-configs/data/projects"
}

shared_auto_github = {
  org  = "yks"
  repo = "gcp-shared-automations"
}

# log_sinks = {
#   audit-logs = {
#     type  = "pubsub"
#     include_children = true
#     destination = "projects/hrzd-audit-logs-0/topics/audit-logs"
#     filter = "logName:\\\"cloudaudit.googleapis.com\\\""
#   },
#   firewall-logs = {
#     type  = "pubsub"
#     include_children = true
#     destination = "projects/hrzd-audit-logs-0/topics/firewall-logs"
#     filter = "resource.type=\\\"gce_subnetwork\\\" logName:\\\"logs/compute.googleapis.com%2Ffirewall\\\""
#   },
#   nat-logs = {
#     type  = "pubsub"
#     include_children = true
#     destination = "projects/hrzd-audit-logs-0/topics/nat-logs"
#     filter = "resource.type=\\\"nat_gateway\\\" logName:\\\"logs/compute.googleapis.com%2Fnat_flows\\\""
#   },
#   swp-logs = {
#     type  = "pubsub"
#     include_children = true
#     destination = "projects/hrzd-audit-logs-0/topics/swp-logs"
#     filter = "resource.type=\\\"networkservices.googleapis.com/Gateway\\\""
#   }
#   ops-agent-logs = {
#     type  = "pubsub"
#     include_children = true
#     destination = "projects/hrzd-audit-logs-0/topics/ops-agent-logs"
#     filter = "resource.type=\\\"gce_instance\\\" AND -protoPayload.@type=\\\"type.googleapis.com/google.cloud.audit.AuditLog\\\""
#   }
#   other-logs = {
#     type  = "pubsub"
#     include_children = true
#     destination = "projects/hrzd-audit-logs-0/topics/others"
#     filter = "NOT (resource.type=\\\"networkservices.googleapis.com/Gateway\\\") && NOT (resource.type=\\\"gce_subnetwork\\\" && logName:\\\"logs/compute.googleapis.com%2Ffirewall\\\") && NOT (logName:\\\"cloudaudit.googleapis.com\\\") && NOT (resource.type=\\\"nat_gateway\\\" logName:\\\"logs/compute.googleapis.com%2Fnat_flows\\\")"
#   }
# }