jraphical = require 'jraphical'
JUser = require '../user'
payment = require 'koding-payment'

module.exports = class JRecurlySubscription extends jraphical.Module

  {secure} = require 'bongo'

  @share()

  @set
    indexes:
      uuid         : 'unique'
    sharedMethods  :
      static       : [
        'all', 'one', 'some',
        'updateUserSubscriptions'
      ]
      instance     : []
    schema         :
      uuid         : String
      planCode     : String
      userCode     : String
      lastUpdate   : Number

  # Recurly web hook will use this method to invalidate the cache.
  @updateUserSubscriptions = secure (client, callback)->
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
            {uuid, plan} = mapAll[k]
            if k not in Object.keys(mapCached)
              sub = new JRecurlySubscription
              sub.uuid = uuid
            else
              sub = mapCached[k]

            console.log uuid

            sub.planCode = plan

            sub.save ->
              console.log arguments
              cb null, sub

        async = require 'async'
        async.parallel stack, (err, results)->
          callback()