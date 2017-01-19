
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
