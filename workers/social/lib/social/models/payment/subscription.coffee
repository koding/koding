jraphical = require 'jraphical'
payment   = require 'koding-payment'

forceRefresh  = yes
forceInterval = 60 * 3

module.exports = class JPaymentSubscription extends jraphical.Module

  {secure} = require 'bongo'
  JUser    = require '../user'
  JPayment = require './index'

  @share()

  @set
    indexes:
      uuid         : 'unique'
    sharedMethods  :
      static       : [
        'getUserSubscriptions', 'getUserSubscriptionsWithPlan', 'checkUserSubscription'
      ]
      instance     : ['cancel', 'resume', 'calculateRefund']
    schema         :
      uuid         : String
      planCode     : String
      userCode     : String
      quantity     : Number
      status       : String
      datetime     : String
      expires      : String
      renew        : String
      amount       : Number
      lastUpdate   : Number

  @getUserSubscriptions = secure ({connection:{delegate}}, callback)->
    @getSubscriptions "user_#{delegate._id}", callback

  @getUserSubscriptionsWithPlan = secure (client, callback)->
    @getUserSubscriptions client, (err, subs)->
      return callback err      if err
      return callback null, [] unless subs

      code = $in: (sub.planCode  for sub in subs)
      JPaymentPlan = require './plan'
      JPaymentPlan.some {code}, {}, (err, plans)->
        return callback err  if err
        planMap = {}
        planMap[plan.code] = plan         for plan in plans
        sub.plan = planMap[sub.planCode]  for sub in subs

        callback null, subs

  @checkUserSubscription = secure ({connection:{delegate}}, planCode, callback)->
    @getAllSubscriptions {
      planCode
      userCode : "user_#{delegate._id}"
      $or      : [
        {status: 'active'}
        {status: 'canceled'}
      ]
    }, callback

  @getGroupSubscriptions = (group, callback)->
    @getSubscriptions "group_#{group._id}", callback

  @getSubscriptions = (paymentMethodId, callback)->
    @getAllSubscriptions { paymentMethodId }, callback

  @getAllSubscriptions = (selector, callback)->
    JPayment.invalidateCacheAndLoad this, selector, {forceRefresh, forceInterval}, callback

  @updateCache = (selector, callback)->
    console.trace()
    JPayment.updateCache
      constructor   : this
      selector      : {userCode: selector.userCode}
      method        : 'getSubscriptions'
      methodOptions : selector.userCode
      keyField      : 'uuid'
      message       : 'user subscriptions'
      forEach       : (uuid, cached, sub, stackCb)=>
        {plan, quantity, status, datetime, expires, renew, amount} = sub
        cached.setData extend cached.getData(), {
          userCode, plan, quantity, status, datetime, expires, renew, amount
        }
        cached.lastUpdate = Date.now()
        cached.save stackCb
    , callback

  refund: (percent, callback)->
    JPaymentPlan = require './plan'
    JPaymentPlan.getPlanWithCode @planCode, (err, plan)=>
      return callback err  if err
      payment.addUserCharge @userCode,
        amount: (-1 * plan.feeMonthly * percent / 100)
      , callback

  calculateRefund: (callback)->
    aDay = 1000 * 60 * 60 * 24
    refundMap = [
      {uplimit: aDay * 1,  percent: 90}
      {uplimit: aDay * 7,  percent: 40}
      {uplimit: aDay * 15, percent: 20}
    ]

    dateNow = new Date()
    dateEnd = new Date(@renew)
    usage   = (dateEnd.getTime() - dateNow.getTime()) / aDay

    refundMap.every (ref)=>
      return callback null, ref.percent  if usage < ref.uplimit
      callback yes, 0

  update_ = (subscription, callback)->
    {status, datetime, expires, plan, quantity, renew, amount} = subscription
    @setData extend @getData(), {status, datetime, expires, plan, quantity, renew, amount}
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
