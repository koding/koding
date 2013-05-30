jraphical = require 'jraphical'
JUser = require '../user'
payment = require 'koding-payment'

forceRefresh = yes

module.exports = class JRecurlySubscription extends jraphical.Module

  {secure} = require 'bongo'

  @share()

  @set
    indexes:
      uuid         : 'unique'
    sharedMethods  :
      static       : [
        'all', 'one', 'some',
        'getSubscriptions'
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
      lastUpdate   : Number

  @getSubscriptions = secure (client, callback)->
    {delegate} = client.connection
    selector =
      userCode : "user_#{delegate._id}"

    unless forceRefresh
      JRecurlySubscription.all selector, callback
    else
      JRecurlySubscription.one {}, (err, sub)=>
        callback err  if err
        unless sub
          @updateCache client, -> JRecurlySubscription.all selector, callback
        else
          sub.lastUpdate ?= 0
          now = (new Date()).getTime()
          if now - sub.lastUpdate > 1000 * 60 * 2
            @updateCache client, -> JRecurlySubscription.all selector, callback
          else
            JRecurlySubscription.all selector, callback

  # Recurly web hook will use this method to invalidate the cache.
  @updateCache = secure (client, callback)->
    console.log "Updating Recurly user subscription..."
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"

    payment.getUserSubscriptions userCode, (err, allSubs)->
      mapAll = {}
      allSubs.forEach (rSub)->
        mapAll[rSub.uuid] = rSub
      JRecurlySubscription.all {userCode}, (err, cachedPlans)->
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

  cancel: secure (client, callback)->
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"
    payment.cancelUserSubscription userCode,
      uuid: @uuid
    , (err, sub)=>
      @status   = sub.status
      @datetime = sub.datetime
      @expires  = sub.expires
      @plan     = sub.plan
      @quantity = sub.quantity
      @renew    = sub.renew
      @save =>
        callback no, @

  resume: secure (client, callback)->
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"
    payment.reactivateUserSubscription userCode,
      uuid: @uuid
    , (err, sub)=>
      @status   = sub.status
      @datetime = sub.datetime
      @expires  = sub.expires
      @plan     = sub.plan
      @quantity = sub.quantity
      @renew    = sub.renew
      @save =>
        callback no, @