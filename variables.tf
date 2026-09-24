variable "name" {
  default     = null
  description = "Name of the budget. If null, a unique name is generated."
}

variable "budget_type" {
  default     = "COST"
  description = "What the budget tracks: 'COST' (spend), 'USAGE' (units consumed), 'RI_UTILIZATION', 'RI_COVERAGE', 'SAVINGS_PLANS_UTILIZATION', or 'SAVINGS_PLANS_COVERAGE'."

  validation {
    condition     = contains(["COST", "USAGE", "RI_UTILIZATION", "RI_COVERAGE", "SAVINGS_PLANS_UTILIZATION", "SAVINGS_PLANS_COVERAGE"], var.budget_type)
    error_message = "budget_type must be one of 'COST', 'USAGE', 'RI_UTILIZATION', 'RI_COVERAGE', 'SAVINGS_PLANS_UTILIZATION', or 'SAVINGS_PLANS_COVERAGE'."
  }
}

variable "time_unit" {
  default     = "MONTHLY"
  description = "Period the budget resets over: 'DAILY', 'MONTHLY', 'QUARTERLY', or 'ANNUALLY'."

  validation {
    condition     = contains(["DAILY", "MONTHLY", "QUARTERLY", "ANNUALLY"], var.time_unit)
    error_message = "time_unit must be one of 'DAILY', 'MONTHLY', 'QUARTERLY', or 'ANNUALLY'."
  }
}

variable "limit_amount" {
  default     = null
  description = "The budgeted amount, as a string (e.g. '500'). Required unless auto_adjust is set, which derives the amount instead."
}

variable "limit_unit" {
  default     = "USD"
  description = "Unit the limit is expressed in — a currency code for a COST budget, or the usage unit (e.g. 'GB') for a USAGE budget."
}

variable "time_period_start" {
  default     = null
  description = "When the budget begins tracking, as 'YYYY-MM-DD_HH:MM' (e.g. '2026-01-01_00:00'). If null, AWS starts it at the current period."
}

variable "time_period_end" {
  default     = null
  description = "When the budget stops tracking, as 'YYYY-MM-DD_HH:MM'. If null, AWS's own far-future default applies and the budget runs indefinitely."
}

variable "auto_adjust" {
  default     = null
  description = "Derives the budget amount automatically instead of fixing it. auto_adjust_type is 'HISTORICAL' (an average of previous periods, sized by historical_options_budget_adjustment_period) or 'FORECAST'. Mutually exclusive with limit_amount."
  type = object({
    auto_adjust_type                            = string
    historical_options_budget_adjustment_period = optional(number)
  })

  validation {
    condition     = var.auto_adjust == null || var.limit_amount == null
    error_message = "auto_adjust derives the budget amount and cannot be combined with an explicit limit_amount."
  }

  validation {
    condition     = var.auto_adjust == null || contains(["HISTORICAL", "FORECAST"], var.auto_adjust.auto_adjust_type)
    error_message = "auto_adjust_type must be either 'HISTORICAL' or 'FORECAST'."
  }
}

variable "cost_filters" {
  default     = {}
  description = "Narrows what the budget counts, keyed by dimension with a list of values (e.g. { Service = ['Amazon Relational Database Service'] }, or { TagKeyValue = ['user:Environment$production'] }). A tag filter uses that 'user:Key$Value' form, which is easy to get wrong and silently matches nothing. If empty, the budget counts all spend in the account."
  type        = map(list(string))
}

variable "cost_types" {
  default     = null
  description = "Which charges count toward a COST budget. Every field defaults to AWS's own behavior when omitted: credits, refunds, taxes, and support are included by default, and use_amortized spreads upfront reservation charges across the term rather than counting them all in the month they were paid."
  type = object({
    include_credit             = optional(bool)
    include_discount           = optional(bool)
    include_other_subscription = optional(bool)
    include_recurring          = optional(bool)
    include_refund             = optional(bool)
    include_subscription       = optional(bool)
    include_support            = optional(bool)
    include_tax                = optional(bool)
    include_upfront            = optional(bool)
    use_amortized              = optional(bool)
    use_blended                = optional(bool)
  })
}

variable "notifications" {
  default     = []
  description = "Who is told when the budget is breached, and at what point. threshold_type 'PERCENTAGE' makes threshold a percentage of the budgeted amount; 'ABSOLUTE_VALUE' makes it a literal amount. notification_type 'ACTUAL' fires on spend already incurred, while 'FORECASTED' fires when AWS projects the period will end over budget — forecasted notifications are the ones that arrive early enough to act on. Each notification needs at least one subscriber; an SNS topic from terraform-aws-sns-topic can fan out further than an email list."
  type = list(object({
    threshold                  = number
    threshold_type             = optional(string, "PERCENTAGE")
    notification_type          = optional(string, "ACTUAL")
    comparison_operator        = optional(string, "GREATER_THAN")
    subscriber_email_addresses = optional(list(string))
    subscriber_sns_topic_arns  = optional(list(string))
  }))

  validation {
    condition     = alltrue([for n in var.notifications : contains(["PERCENTAGE", "ABSOLUTE_VALUE"], n.threshold_type)])
    error_message = "A notification's threshold_type must be 'PERCENTAGE' or 'ABSOLUTE_VALUE'."
  }

  validation {
    condition     = alltrue([for n in var.notifications : contains(["ACTUAL", "FORECASTED"], n.notification_type)])
    error_message = "A notification's notification_type must be 'ACTUAL' or 'FORECASTED'."
  }

  validation {
    condition     = alltrue([for n in var.notifications : contains(["GREATER_THAN", "LESS_THAN", "EQUAL_TO"], n.comparison_operator)])
    error_message = "A notification's comparison_operator must be 'GREATER_THAN', 'LESS_THAN', or 'EQUAL_TO'."
  }

  validation {
    condition = alltrue([
      for n in var.notifications :
      length(coalesce(n.subscriber_email_addresses, [])) + length(coalesce(n.subscriber_sns_topic_arns, [])) > 0
    ])
    error_message = "Each notification needs at least one subscriber, an email address or an SNS topic, or it notifies nobody."
  }
}

variable "tags" {
  default     = null
  description = "A map of tags to assign to the budget."
}
