
module.exports =
  Status:
    # allowed statuses
    ACTIVE: 'active'
    TRIALING: 'trialing'
    EXPIRING: 'expiring'

    # not allowed stripe statuses
    EXPIRED: 'expired'
    PAST_DUE: 'past_due'
    UNPAID: 'unpaid'

    # not allowed koding statuses
    CANCELED: 'no status'
    NEEDS_UPGRADE: 'no payment'
    UNKNOWN: 'unknown'

  Plan:
    FREE: 'p_free'
    FREE_FOREVER: 'p_free_forever'
    UP_TO_10_USERS: 'p_up_to_10'
    UP_TO_50_USERS: 'p_up_to_50'
    OVER_50_USERS: 'p_over_50'
  Trial:
    ALMOST_EXPIRED_DAYS_LEFT: 4

  AddOns:
    price: 5000

  SupportPlans:
    [
      {
        name : 'Basic'
        price : 1000
        period : 'month'
        features : [
          '4 Hours dedicated support'
          'Stack script support'
          '24 Hours response time'
          'General Troubleshooting'
        ]
      }
      {
        name : 'Business'
        price : 5000
        period : 'month'
        features : [
          '25 Hours dedicated support'
          'Stack script support'
          '4 Hours response time'
          'General Troubleshooting'
        ]
      }
      {
        name : 'Enterprise'
        price : null
        period : null
        features : [
          'On-premise installation'
          'On-site support'
          'Phone support'
          '24/7 Coverage'
        ]
      }
    ]
