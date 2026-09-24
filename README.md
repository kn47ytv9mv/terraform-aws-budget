# terraform-aws-budget

Terraform module for an AWS Budget — a spend or usage threshold that
notifies someone before the bill becomes a surprise.

## Cost

AWS provides the first two budgets free per account and bills a small
amount per budget per day beyond that. See AWS's
[Cost Management pricing](https://aws.amazon.com/aws-cost-management/pricing/)
page for current rates.

## Design

**A budget with no notifications tells nobody anything.** It tracks
spend in the console and that is all. `notifications` is where the
value is, and each entry needs at least one subscriber — enforced at
plan time here, since AWS accepts a budget with none.

`notification_type` is the choice that matters most:

- `'ACTUAL'` fires on spend already incurred. By the time an 80% actual
  notification arrives, that money is spent.
- `'FORECASTED'` fires when AWS projects the period will *end* over
  budget. These arrive early enough to act on, which is usually the
  point.

Setting both, at different thresholds, is the common pattern — a
forecasted warning early and an actual one as confirmation.

`cost_filters` narrows what counts. A tag filter uses the
`'user:Key$Value'` form (`{ TagKeyValue = ["user:Environment$production"] }`),
which is easy to get wrong and **silently matches nothing** rather than
erroring — a budget filtered this way can read zero forever while spend
continues.

`auto_adjust` derives the amount from history or forecast instead of
fixing it, which suits a growing account where a fixed number goes
stale. It is mutually exclusive with `limit_amount`.

Pair with
[`terraform-aws-sns-topic`](https://github.com/kn47ytv9mv/terraform-aws-sns-topic)
through `subscriber_sns_topic_arns` to fan a notification out further
than an email list reaches.

## Usage

```hcl
module "budget" {
  source = "kn47ytv9mv/budget/aws"

  name         = "monthly-spend"
  limit_amount = "500"

  notifications = [
    { threshold = 80, subscriber_email_addresses = ["ops@example.com"] },
    { threshold = 100, notification_type = "FORECASTED", subscriber_email_addresses = ["ops@example.com"] },
  ]
}
```

Or directly from this repository, scoped to one service and notifying a
topic:

```hcl
module "budget" {
  source = "github.com/kn47ytv9mv/terraform-aws-budget"

  name         = "rds-spend"
  limit_amount = "200"

  cost_filters = {
    Service = ["Amazon Relational Database Service"]
  }

  notifications = [
    {
      threshold                 = 90
      notification_type         = "FORECASTED"
      subscriber_sns_topic_arns = [module.alerts.arn]
    },
  ]
}
```

## Requirements

| Name | Version |
|---|---|
| terraform | >= 1.9 |
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Providers

| Name | Version |
|---|---|
| aws | ~> 6.61 |
| random | ~> 3.9 |

## Inputs

| Name | Description | Default | Required |
|---|---|---|---|
| name | Name of the budget. If null, a unique name is generated. | `null` | no |
| budget_type | What the budget tracks: `'COST'`, `'USAGE'`, or one of the RI/Savings Plans variants. | `"COST"` | no |
| time_unit | Period the budget resets over: `'DAILY'`, `'MONTHLY'`, `'QUARTERLY'`, or `'ANNUALLY'`. | `"MONTHLY"` | no |
| limit_amount | The budgeted amount, as a string. Required unless `auto_adjust` is set. | `null` | no |
| limit_unit | Unit the limit is expressed in — a currency code, or a usage unit. | `"USD"` | no |
| time_period_start | When tracking begins, as `'YYYY-MM-DD_HH:MM'`. | `null` | no |
| time_period_end | When tracking stops, as `'YYYY-MM-DD_HH:MM'`. | `null` | no |
| auto_adjust | Derives the amount from history or forecast. Mutually exclusive with `limit_amount`. | `null` | no |
| cost_filters | Narrows what the budget counts, keyed by dimension. Tag filters use the `'user:Key$Value'` form. | `{}` | no |
| cost_types | Which charges count toward a COST budget. Every field defaults to AWS's own behavior. | `null` | no |
| notifications | Who is told when the budget is breached, and at what point. Each needs at least one subscriber. | `[]` | no |
| tags | A map of tags to assign to the budget. | `null` | no |

## Outputs

| Name | Description |
|---|---|
| id | The ID of the budget. |
| arn | The ARN of the budget. |
| name | The name of the budget. |

## License

MIT — see [LICENSE.md](LICENSE.md).
