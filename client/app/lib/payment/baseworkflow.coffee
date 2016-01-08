kd                = require 'kd'
KDController      = kd.Controller
PaymentConstants  = require './paymentconstants'


module.exports = class BaseWorkFlow extends KDController


  constructor: (options = {}, data) ->

    super options, data

    @state = kd.utils.extend @getInitialState(), options.state


  getInitialState: -> {
    failedAttemptCount : 0
  }


  increaseFailedAttemptCount: -> @state.failedAttemptCount++


  isExceedFailedAttemptCount: (limit) -> @state.failedAttemptCount >= limit


  failedAttemptLimitReached: (blockUser = yes) ->

    kd.utils.defer =>
      @blockUserForTooManyAttempts()  if blockUser
      @modal?.emit 'FailedAttemptLimitReached'


  blockUserForTooManyAttempts: ->
