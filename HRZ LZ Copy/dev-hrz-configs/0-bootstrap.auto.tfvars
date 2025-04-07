outputs_location = "../dev-hrz-configs"
prefix           = "hrzd"

global_billing = {
  account        = "turkiz"
  created_in_org = false
}

organization = {
  domain      = "dev.horizon285.com"
  id          = 942984779434
  customer_id = "C02cr50ow"
}

org_policies_config = {
  import_defaults = true
}

groups = {
  # gcp-billing-admins      = "gcp-billing-admins"
  # gcp-devops              = "gcp-devops"
  # gcp-network-admins      = "gcp-network-admins"
  gcp-organization-admins = "gcp-organization-admins"
  gcp-security-admins     = "gcp-cyber-admins"
  # gcp-fw-admins           = "cyber-palo-admin"
  # # aliased to gcp-devops as the checklist does not create it
  # gcp-support           = "gcp-devops"
  gcp-mamram-sa         = "mamram-solution-architects"
  # gcp-data-admins       = "gcp-data-admins"
  # gcp-distribute-admins = "gcp-distribute-admins"
  # gcp-finops-admins     = "gcp-finops-admins"
}

factories_config = {
  data_dir = "../dev-hrz-configs/data/0-bootstrap"
}

billing_accounts = {
  turkiz = {
    organization_id = 1049990874915
    id              = "01A98A-A178F7-4BC158"
    created_in_org  = false
  },
  green = {
    organization_id = 1049990874915
    id              = "01A98A-A178F7-4BC158"
    created_in_org  = false
  }
}
github = {
  org  = "ayen318"
  repo = "hrz-lz"
}
