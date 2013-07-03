jraphical = require 'jraphical'
JUser = require '../user'
payment = require 'koding-payment'

forceRefresh  = yes
forceInterval = 0

module.exports = class JRecurlySubscription extends jraphical.Module

  {secure} = require 'bongo'

  @share()

  @set
    indexes:
      uuid         : 'unique'
    sharedMethods  :
      static       : [
        'getUserSubscriptions', 'checkUserSubscription'
      ]
      instance     : [
        'cancel', 'resume', 'calculateRefund'
      ]
    schema         :
      uuid         : String
      planCode     : String
      userCode     : String
      quantity     : Number
      status       : String
      datetime     : String
      expires      : String
      renew        : String
      lastUpdate   : Number

  @getUserSubscriptions = secure (client, callback)->
    {delegate} = client.connection
    JRecurlySubscription.getSubscriptions "user_#{delegate._id}", callback

  @checkUserSubscription = secure (client, planCode, callback)->
    {delegate} = client.connection
    userCode  = "user_#{delegate._id}"

    JRecurlySubscription.getSubscriptionsAll userCode,
      userCode : userCode
      planCode : planCode
    , callback

  @getGroupSubscriptions = (group, callback)->
    JRecurlySubscription.getSubscriptions "group_#{group._id}", callback

  @getSubscriptions = (userCode, callback)->
    JRecurlySubscription.getSubscriptionsAll userCode,
      userCode : userCode
    , callback

  @getSubscriptionsAll = (userCode, selector, callback)->
    unless forceRefresh
      JRecurlySubscription.all selector, callback
    else
      JRecurlySubscription.one selector, (err, sub)=>
        callback err  if err
        unless sub
          @updateCache userCode, selector, -> JRecurlySubscription.all selector, callback
        else
          sub.lastUpdate ?= 0
          now = (new Date()).getTime()
          if now - sub.lastUpdate > 1000 * forceInterval
            @updateCache userCode, selector, -> JRecurlySubscription.all selector, callback
          else
            JRecurlySubscription.all selector, callback

  # Recurly web hook will use this method to invalidate the cache.
  @updateCache = (userCode, selector, callback)->
    console.log "Updating Recurly user subscription..."

    payment.getUserSubscriptions userCode, (err, allSubs)->
      mapAll = {}
      allSubs.forEach (rSub)->
        mapAll[rSub.uuid] = rSub
      JRecurlySubscription.all {selector}, (err, cachedPlans)->
        mapCached = {}
        cachedPlans.forEach (cSub)->
          mapCached[cSub.uuid] = cSub
        stack = []
        Object.keys(mapCached).forEach (k)->
          if k not in Object.keys(mapAll)
            # delete
            stack.push (cb)->
              mapCached[k].remove ->
                cb()
        Object.keys(mapAll).forEach (k)->
          # create or update
          stack.push (cb)->
            {uuid, plan, quantity, status, datetime, expires, renew} = mapAll[k]
            JRecurlySubscription.one
              uuid: k
            , (err, sub)->
              if err or not sub
                sub = new JRecurlySubscription
                sub.uuid = uuid

              sub.userCode = userCode
              sub.planCode = plan
              sub.quantity = quantity
              sub.status   = status
              sub.datetime = datetime
              sub.expires  = expires
              sub.renew    = renew

              sub.lastUpdate = (new Date()).getTime()

              sub.save ->
                cb null, sub

        async = require 'async'
        async.parallel stack, (err, results)->
          callback()

  update: (quantity, callback)->
    payment.updateUserSubscription @userCode,
      uuid     : @uuid
      plan     : @planCode
      quantity : quantity
    , (err, sub)=>
      return callback yes  if err
      @status   = sub.status
      @datetime = sub.datetime
      @expires  = sub.expires
      @planCode = sub.plan
      @quantity = sub.quantity
      @renew    = sub.renew
      @save =>
        callback no, @

  refund: (percent, callback)->
    JRecurlyPlan = require './index'
    JRecurlyPlan.getPlanWithCode @planCode, (err, plan)=>
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
      if usage < ref.uplimit
        callback yes, ref.percent
        return no
      callback no, 0
      return yes

  terminate: (callback)->
    payment.terminateUserSubscription @userCode,
      uuid   : @uuid
      refund : "none"
    , (err, sub)=>
      return callback err  if err

      @calculateRefund (status, percent)=>
        if status
          @refund percent, ->
            console.log "Refunding #{percent}% of the payment."

      @status   = sub.status
      @datetime = sub.datetime
      @expires  = sub.expires
      @planCode = sub.plan
      @quantity = sub.quantity
      @renew    = sub.renew
      @save =>
        callback no, @

  cancel: (callback)->
    payment.cancelUserSubscription @userCode,
      uuid: @uuid
    , (err, sub)=>
      return callback err  if err
      @status   = sub.status
      @datetime = sub.datetime
      @expires  = sub.expires
      @planCode = sub.plan
      @quantity = sub.quantity
      @renew    = sub.renew
      @save =>
        callback no, @

  resume: (callback)->
    payment.reactivateUserSubscription @userCode,
      uuid: @uuid
    , (err, sub)=>
      return callback err  if err
      @status   = sub.status
      @datetime = sub.datetime
      @expires  = sub.expires
      @planCode = sub.plan
      @quantity = sub.quantity
      @renew    = sub.renew
      @save =>
        callback no, @