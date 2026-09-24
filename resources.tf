resource "random_uuid" "resource" {}

resource "aws_budgets_budget" "resource" {
  name        = coalesce(var.name, random_uuid.resource.id)
  budget_type = var.budget_type
  time_unit   = var.time_unit

  limit_amount = var.limit_amount
  limit_unit   = var.limit_unit

  time_period_start = var.time_period_start
  time_period_end   = var.time_period_end

  dynamic "cost_filter" {
    for_each = var.cost_filters

    content {
      name   = cost_filter.key
      values = cost_filter.value
    }
  }

  dynamic "cost_types" {
    for_each = var.cost_types[*]

    content {
      include_credit             = cost_types.value.include_credit
      include_discount           = cost_types.value.include_discount
      include_other_subscription = cost_types.value.include_other_subscription
      include_recurring          = cost_types.value.include_recurring
      include_refund             = cost_types.value.include_refund
      include_subscription       = cost_types.value.include_subscription
      include_support            = cost_types.value.include_support
      include_tax                = cost_types.value.include_tax
      include_upfront            = cost_types.value.include_upfront
      use_amortized              = cost_types.value.use_amortized
      use_blended                = cost_types.value.use_blended
    }
  }

  dynamic "auto_adjust_data" {
    for_each = var.auto_adjust[*]

    content {
      auto_adjust_type = auto_adjust_data.value.auto_adjust_type

      dynamic "historical_options" {
        for_each = auto_adjust_data.value.historical_options_budget_adjustment_period[*]

        content {
          budget_adjustment_period = historical_options.value
        }
      }
    }
  }

  dynamic "notification" {
    for_each = var.notifications

    content {
      threshold                  = notification.value.threshold
      threshold_type             = notification.value.threshold_type
      notification_type          = notification.value.notification_type
      comparison_operator        = notification.value.comparison_operator
      subscriber_email_addresses = notification.value.subscriber_email_addresses
      subscriber_sns_topic_arns  = notification.value.subscriber_sns_topic_arns
    }
  }

  tags = var.tags
}

output "id" {
  description = "The ID of the budget."
  value       = aws_budgets_budget.resource.id
}

output "arn" {
  description = "The ARN of the budget."
  value       = aws_budgets_budget.resource.arn
}

output "name" {
  description = "The name of the budget."
  value       = aws_budgets_budget.resource.name
}
