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
    selector   =
      userCode : userCode

    unless forceRefresh
      JRecurlySubscription.all selector, callback
    else
      JRecurlySubscription.one selector, (err, sub)=>
        callback err  if err
        unless sub
          @updateCache userCode, -> JRecurlySubscription.all selector, callback
        else
          sub.lastUpdate ?= 0
          now = (new Date()).getTime()
          if now - sub.lastUpdate > 1000 * forceInterval
            @updateCache userCode, -> JRecurlySubscription.all selector, callback
          else
            JRecurlySubscription.all selector, callback

  # Recurly web hook will use this method to invalidate the cache.
  @updateCache = (userCode, callback)->
    console.log "Updating Recurly user subscription..."

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
      return callback yes  if err
      @status   = sub.status
      @datetime = sub.datetime
      @expires  = sub.expires
      @planCode = sub.plan
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
      return callback yes  if err
      @status   = sub.status
      @datetime = sub.datetime
      @expires  = sub.expires
      @planCode = sub.plan
      @quantity = sub.quantity
      @renew    = sub.renew
      @save =>
        callback no, @