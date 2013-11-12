jraphical = require 'jraphical'
payment   = require 'koding-payment'

forceRefresh  = yes
forceInterval = 60 * 3

module.exports = class JPaymentSubscription extends jraphical.Module

  {secure, dash} = require 'bongo'
  JUser    = require '../user'
  JPayment = require './index'

  @share()

  @set
    indexes:
      uuid         : 'unique'
    sharedMethods  :
      static       : [
        'fetchUserSubscriptions', 'fetchUserSubscriptionsWithPlan', 'checkUserSubscription'
      ]
      instance     : ['cancel', 'resume', 'calculateRefund']
    schema         :
      uuid         : String
      planCode     : String
      userCode     : String
      quantity     :
        type       : Number
        default    : 1
      status       : String
      activatedAt  : Date
      expiresAt    : Date
      renewAt      : Date
      feeAmount    : Number
      lastUpdate   : Number

  @fetchUserSubscriptions = secure ({ connection:{ delegate }}, callback) ->
    delegate.fetchPaymentMethods (err, paymentMethods) =>
      return callback err  if err
      subscriptions = {}
      queue = paymentMethods.map ({ paymentMethodId }) => =>
        @fetchSubscriptions paymentMethodId, (err, subs) ->
          return queue.fin err  if err
          subscriptions[paymentMethodId] = subs  if subs.length
          queue.fin()
      dash queue, -> callback null, subscriptions

  @fetchUserSubscriptionsWithPlan = secure (client, callback)->
    @fetchUserSubscriptions client, (err, subs)->
      return callback err      if err
      return callback null, [] unless subs

      planCode = $in: (sub.planCode for sub in subs)
      JPaymentPlan = require './plan'
      JPaymentPlan.some { planCode }, {}, (err, plans)->
        return callback err  if err
        planMap = {}
        planMap[plan.planCode] = plan         for plan in plans
        sub.plan = planMap[sub.planCode]  for sub in subs

        callback null, subs

  @checkUserSubscription = secure ({connection:{delegate}}, planCode, callback)->
    @fetchAllSubscriptions {
      planCode
      userCode : "user_#{delegate._id}"
      $or      : [
        {status: 'active'}
        {status: 'canceled'}
      ]
    }, callback

  @getGroupSubscriptions = (group, callback)->
    @fetchSubscriptions "group_#{group._id}", callback

  @fetchSubscriptions = (paymentMethodId, callback) ->
    @fetchAllSubscriptions { paymentMethodId }, callback

  @fetchAllSubscriptions = (selector, callback, rest...) ->
    JPayment.invalidateCacheAndLoad this, selector, {forceRefresh, forceInterval}, callback

  @updateCache = (selector, callback)->
    JPayment.updateCache
      constructor   : this
      selector      : { paymentMethodId: selector.paymentMethodId }
      method        : 'fetchSubscriptions'
      methodOptions : selector.paymentMethodId
      keyField      : 'uuid'
      message       : 'user subscriptions'
      forEach       : (uuid, cached, sub, stackCb)=>
        {plan, quantity, status, activatedAt, expiresAt, renewAt, amount} = sub
        cached.setData extend cached.getData(), {
          userCode, plan, quantity, status, activatedAt, expiresAt, renewAt, amount
        }
        cached.lastUpdate = Date.now()
        cached.save stackCb
    , callback

  refund: (percent, callback)->
    JPaymentPlan = require './plan'
    JPaymentPlan.fetchPlanByCode @planCode, (err, plan) =>
      return callback err  if err
      payment.addUserCharge @userCode,
        amount: -1 * plan.feeAmount * percent / 100
      , callback

  calculateRefund: (callback)->
    aDay = 1000 * 60 * 60 * 24
    refundMap = [
      {uplimit: aDay * 1,  percent: 90}
      {uplimit: aDay * 7,  percent: 40}
      {uplimit: aDay * 15, percent: 20}
    ]

    dateNow = new Date
    dateEnd = @renewAt
    usage   = (dateEnd - dateNow) / aDay

    refundMap.every (ref)=>
      return callback null, ref.percent  if usage < ref.uplimit
      callback yes, 0

  update_ = (subscription, callback)->
    {status, activatedAt, expiresAt, plan, quantity, renewAt, amount} = subscription
    @setData extend @getData(), {
      status, activatedAt, expiresAt, plan, quantity, renewAt, amount
    }
    @save (err)-> callback err, this

  update: (quantity, callback)->
    payment.updateSubscription @userCode, {@uuid, plan: @planCode, quantity}, (err, sub)=>
      return callback err  if err
      update_ sub, callback

  terminate: (callback)->
    payment.terminateSubscription @userCode, {@uuid, refund : 'none'}, (err, sub)=>
      return callback err  if err

      @calculateRefund (err, percent)=>
        unless err
          @refund percent, ->
            console.log "Refunding #{percent}% of subscription #{@uuid}."

      update_ sub, callback

  cancel: (callback)->
    payment.cancelSubscription @userCode, {@uuid}, (err, sub)=>
      return callback err  if err
      update_ sub, callback

  resume: (callback)->
    payment.reactivateUserSubscription @userCode, {@uuid}, (err, sub)=>
      return callback err  if err
      update_ sub, callback
