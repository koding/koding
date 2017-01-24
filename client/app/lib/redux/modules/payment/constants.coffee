
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
    SOLO: 'p_solo'
    GENERAL: 'p_general'
  Trial:
    ALMOST_EXPIRED_DAYS_LEFT: 4
