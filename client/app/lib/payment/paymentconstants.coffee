globals = require 'globals'

module.exports =

  getOperation : (current, selected) ->

    arr = [
      @planTitle.FREE
      @planTitle.HOBBYIST
      @planTitle.DEVELOPER
      @planTitle.PROFESSIONAL
    ]

    current  = arr.indexOf current
    selected = arr.indexOf selected

    return switch
      when selected >  current then @operation.UPGRADE
      when selected is current then @operation.INTERVAL_CHANGE
      when selected <  current then @operation.DOWNGRADE


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
  TOO_MANY_ATTEMPT_BLOCK_DURATION: globals.config.paymentBlockDuration

  error:
    ERR_USER_NOT_CONFIRMED: 'You need to confirm your email to purchase a Koding subscription.'

