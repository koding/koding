PaymentConstants =

  planInterval:
    MONTH       : 'month'
    YEAR        : 'year'

  planTitle:
    FREE         : 'free'
    HOBBYIST     : 'hobbyist'
    DEVELOPER    : 'developer'
    PROFESSIONAL : 'professional'

  provider:
    STRIPE : 'stripe'
    PAYPAL : 'paypal'
    KODING : 'koding'

  operation:
    UPGRADE         : 1
    INTERVAL_CHANGE : 0
    DOWNGRADE       : -1

  FAILED_ATTEMPT_LIMIT: 3
  TOO_MANY_ATTEMPT_BLOCK_KEY: 'BlockForTooManyAttempts'
  TOO_MANY_ATTEMPT_BLOCK_DURATION: KD.config.paymentBlockDuration


