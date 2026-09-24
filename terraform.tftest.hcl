mock_provider "aws" {}

run "invalid_budget_type_is_rejected" {
  command = plan

  variables {
    budget_type  = "SPEND"
    limit_amount = "500"
  }

  expect_failures = [var.budget_type]
}

run "invalid_time_unit_is_rejected" {
  command = plan

  variables {
    time_unit    = "FORTNIGHTLY"
    limit_amount = "500"
  }

  expect_failures = [var.time_unit]
}

run "auto_adjust_conflicts_with_an_explicit_limit" {
  command = plan

  variables {
    limit_amount = "500"
    auto_adjust  = { auto_adjust_type = "HISTORICAL" }
  }

  expect_failures = [var.auto_adjust]
}

run "invalid_auto_adjust_type_is_rejected" {
  command = plan

  variables {
    auto_adjust = { auto_adjust_type = "GUESS" }
  }

  expect_failures = [var.auto_adjust]
}

run "invalid_notification_threshold_type_is_rejected" {
  command = plan

  variables {
    limit_amount = "500"
    notifications = [
      { threshold = 80, threshold_type = "FRACTION", subscriber_email_addresses = ["ops@example.com"] },
    ]
  }

  expect_failures = [var.notifications]
}

run "notification_without_a_subscriber_is_rejected" {
  command = plan

  variables {
    limit_amount = "500"
    notifications = [
      { threshold = 80 },
    ]
  }

  expect_failures = [var.notifications]
}

run "name_defaults_to_random_uuid" {
  command = apply

  variables {
    limit_amount = "500"
  }

  assert {
    condition     = aws_budgets_budget.resource.name == random_uuid.resource.id
    error_message = "Leaving name unset should fall back to the generated random_uuid."
  }
}

run "defaults_are_a_monthly_cost_budget" {
  command = plan

  variables {
    limit_amount = "500"
  }

  assert {
    condition     = aws_budgets_budget.resource.budget_type == "COST"
    error_message = "A budget should default to tracking cost."
  }

  assert {
    condition     = aws_budgets_budget.resource.time_unit == "MONTHLY"
    error_message = "A budget should default to a monthly period."
  }

  assert {
    condition     = aws_budgets_budget.resource.limit_unit == "USD"
    error_message = "A cost budget's limit should default to USD."
  }
}

run "auto_adjust_creates_one_block_without_a_limit_amount" {
  command = plan

  variables {
    auto_adjust = { auto_adjust_type = "FORECAST" }
  }

  assert {
    condition     = length(aws_budgets_budget.resource.auto_adjust_data) == 1
    error_message = "Setting auto_adjust should emit exactly one auto_adjust_data block."
  }

  assert {
    condition     = one(aws_budgets_budget.resource.auto_adjust_data).auto_adjust_type == "FORECAST"
    error_message = "The auto adjust type should pass through unchanged."
  }
}

run "notifications_default_to_actual_percentage_greater_than" {
  command = plan

  variables {
    limit_amount = "500"
    notifications = [
      { threshold = 80, subscriber_email_addresses = ["ops@example.com"] },
    ]
  }

  assert {
    condition     = one(aws_budgets_budget.resource.notification).threshold_type == "PERCENTAGE"
    error_message = "A notification threshold should default to a percentage of the budget."
  }

  assert {
    condition     = one(aws_budgets_budget.resource.notification).notification_type == "ACTUAL"
    error_message = "A notification should default to firing on actual spend."
  }

  assert {
    condition     = one(aws_budgets_budget.resource.notification).comparison_operator == "GREATER_THAN"
    error_message = "A notification should default to firing when spend exceeds the threshold."
  }
}

run "cost_filters_create_one_block_each" {
  command = plan

  variables {
    limit_amount = "500"
    cost_filters = {
      Service     = ["Amazon Relational Database Service"]
      TagKeyValue = ["user:Environment$production"]
    }
  }

  assert {
    condition     = length(aws_budgets_budget.resource.cost_filter) == 2
    error_message = "Each cost_filters entry should produce one cost_filter block."
  }
}

run "no_optional_blocks_by_default" {
  command = plan

  variables {
    limit_amount = "500"
  }

  assert {
    condition     = length(aws_budgets_budget.resource.cost_types) == 0
    error_message = "Leaving cost_types unset should emit no cost_types block."
  }

  assert {
    condition     = length(aws_budgets_budget.resource.auto_adjust_data) == 0
    error_message = "Leaving auto_adjust unset should emit no auto_adjust_data block."
  }

  assert {
    condition     = length(aws_budgets_budget.resource.notification) == 0
    error_message = "Leaving notifications unset should emit no notification blocks."
  }
}

run "readme_default_example" {
  command = plan

  variables {
    name         = "monthly-spend"
    limit_amount = "500"

    notifications = [
      { threshold = 80, subscriber_email_addresses = ["ops@example.com"] },
      { threshold = 100, notification_type = "FORECASTED", subscriber_email_addresses = ["ops@example.com"] },
    ]
  }
}

run "readme_service_scoped_example" {
  command = plan

  variables {
    name         = "rds-spend"
    limit_amount = "200"

    cost_filters = {
      Service = ["Amazon Relational Database Service"]
    }

    notifications = [
      {
        threshold                 = 90
        notification_type         = "FORECASTED"
        subscriber_sns_topic_arns = ["arn:aws:sns:us-east-1:123456789012:alerts"]
      },
    ]
  }
}
