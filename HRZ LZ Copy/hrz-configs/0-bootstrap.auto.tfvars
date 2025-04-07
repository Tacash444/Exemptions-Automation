outputs_location = "../hrz-configs"
prefix           = "hrz"

global_billing = {
  account        = "turkiz"
  created_in_org = false
}

organization = {
  domain      = "horizon285.com"
  id          = 986108084926
  customer_id = "C01xhtnf9"
}

tf_apply_auto_sa = "serviceAccount:terraform-apply-auto-0@hrz-prod-automations-0.iam.gserviceaccount.com"

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
  data_dir = "../hrz-configs/data/0-bootstrap"
}

billing_accounts = {
  turkiz = {
    organization_id = 1049990874915
    id              = "01A98A-A178F7-4BC158"
    created_in_org  = false
  },
  green = {
    organization_id = 199064130082
    id              = "0130ED-A5BD97-DBEFAF"
    created_in_org  = false
  }
  white = {
    organization_id = 738625299263
    id             = "0183A1-38172C-8A82A9"
    created_in_org = false
  }
}
github = {
  org  = "ayen318"
  repo = "hrz-lz"
}
