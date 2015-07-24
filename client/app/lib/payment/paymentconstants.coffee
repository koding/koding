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


  FAILED_ATTEMPTS       :
    PRICING             :
      LIMIT             : 3
      KEY               : 'PricingBlockForTooManyAttempts'
      DURATION          : globals.config.paymentBlockDuration

    UPDATE_CREDIT_CARD  :
      LIMIT             : 3
      KEY               : 'UpdateCreditCardBlockForTooManyAttempts'
      DURATION          : globals.config.paymentBlockDuration

  error:
    ERR_USER_NOT_CONFIRMED: 'Sorry, you need to confirm your email address first.'

  events:
    WORKFLOW_STARTED          : 'WorkflowStarted'
    WORKFLOW_COULD_NOT_START  : 'WorkflowCouldNotStart'
