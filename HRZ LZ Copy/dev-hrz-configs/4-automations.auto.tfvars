functions_config = {
  data_path            = "functions"
  bucket_name          = "iac-functions-04"
  service_account_name = "functions-sa"
}

workflows_config = {
  data_path            = "workflows"
  service_account_name = "workflows-sa"
}

github_automations_repo = {
  name = "gcp-platform"
}
