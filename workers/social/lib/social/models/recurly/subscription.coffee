jraphical = require 'jraphical'
JUser = require '../user'
payment = require 'koding-payment'

forceRefresh  = yes
forceInterval = 60 * 1

module.exports = class JRecurlySubscription extends jraphical.Module

  {secure} = require 'bongo'

  @share()

  @set
    indexes:
      uuid         : 'unique'
    sharedMethods  :
      static       : [
        'getUserSubscriptions'
      ]
      instance     : [
        'cancel', 'resume'
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
      expensed     : Number
      lastUpdate   : Number

  @getUserSubscriptions = secure (client, callback)->
    {delegate} = client.connection
    JRecurlySubscription.getSubscriptions "user_#{delegate._id}", callback

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

    payment.getUserSubscriptions selector, (err, allSubs)->
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
            if k not in Object.keys(mapCached)
              sub = new JRecurlySubscription
              sub.uuid = uuid
            else
              sub = mapCached[k]

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

  cancel: (callback)->
    payment.cancelUserSubscription @userCode,
      uuid: @uuid
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

  resume: (callback)->
    payment.reactivateUserSubscription @userCode,
      uuid: @uuid
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