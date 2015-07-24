kd                = require 'kd'
KDController      = kd.Controller
PaymentConstants  = require './paymentconstants'


module.exports = class BaseWorkFlow extends KDController

  getInitialState: -> {
    failedAttemptCount : 0
  }


  constructor: (options = {}, data) ->

    @state = kd.utils.extend @getInitialState(), options.state

    super options, data


  increaseFailedAttemptCount: -> @state.failedAttemptCount++


  isExceedFailedAttemptCount: (limit = PaymentConstants.FAILED_ATTEMPTS.PRICING.LIMIT) ->

    return @state.failedAttemptCount >= limit


  failedAttemptLimitReached: (blockUser = yes) ->

    kd.utils.defer =>
      @blockUserForTooManyAttempts()  if blockUser
      @modal?.emit 'FailedAttemptLimitReached'


  blockUserForTooManyAttempts: ->

