locals {
  default_budget_config = {
    thresholds = [
    {
      percent    = 0.5
      forecasted_spend = false
    },
    {
      percent = 0.8
      forecasted_spend = false
    }
    ]
  }
}

module "budgets" {
  source = "../modules/billing-account"
  for_each = {
    for k, v in local.projects : k => v if try(v.budget, null) != null
  }

  id = each.value.billing_account
  budgets = {
    lookup(each.value.budget, "name") = {
      display_name = lookup(each.value.budget, "name")
      amount = {
        units = try(each.value.budget.amount, 100)
      }
      filter = {
        credit_treatment = (
          try(each.value.budget.filters.include_credits, null) == false
          ? {exclude_all = "EXCLUDE_ALL_CREDITS"}
          : null
        )
        

        projects = ["projects/${module.projects[each.key].number}"]
        services = (try(each.value.budget.filters.include_services, null) == null
          ? null
        : [for s in each.value.budget.filters.include_services : "services/${s}"])
      }
      threshold_rules = (
        lookup(each.value.budget, "thresholds", null) == null
        ? local.default_budget_config.thresholds
        : concat([
          for threshold in each.value.budget.thresholds.current : {
            percent          = threshold
            forecasted_spend = false
          }
          ], [
          for threshold in each.value.budget.thresholds.forecasted : {
            percent          = threshold
            forecasted_spend = true
          }
        ])
      )
    }
  }

}
