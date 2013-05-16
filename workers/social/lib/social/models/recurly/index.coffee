jraphical = require 'jraphical'

#
forceRefresh = yes

module.exports = class JRecurlyPlan extends jraphical.Module

  {secure} = require 'bongo'

  @share()

  @set
    indexes:
      code         : 'unique'
    sharedMethods  :
      static       : ['getPlans']
      instance     : []
    schema         :
      code         : String
      title        : String
      desc         : String
      feeMonthly   : Number
      feeInitial   : Number
      product      :
        prefix     : String
        category   : String
        item       : String
        version    : Number
      lastUpdate   : Number

  @create = (data, callback)->
    recurlyPlan = new JRecurlyPlan
    recurlyPlan.lastUpdate = new Date()
    recurlyPlan.save -> callback

  @getPlans = secure (client, prefix, callback)->
    unless forceRefresh
      JRecurlyPlan.all {'product.prefix': prefix}, callback
    else
      JRecurlyPlan.one {}, (err, plan)=>
        callback err  if err
        unless plan
          @updateCache -> JRecurlyPlan.all {'product.prefix': prefix}, callback
        else
          plan.lastUpdate ?= 0
          now = new Date()
          if now - plan.lastUpdate > 100 * 60 * 30
            @updateCache -> JRecurlyPlan.all {'product.prefix': prefix}, callback
          else
            JRecurlyPlan.all {'product.prefix': prefix}, callback

  # Recurly web hook will use this method to invalidate the cache.
  @updateCache = (callback)->
    console.log "Updating Recurly plans..."
    payment = require 'koding-payment'

    payment.getPlans (err, allPlans)->
      mapAll = {}
      allPlans.forEach (rPlan)->
        mapAll[rPlan.code] = rPlan
      JRecurlyPlan.all {}, (err, cachedPlans)->
        mapCached = {}
        cachedPlans.forEach (cPlan)->
          mapCached[cPlan.code] = cPlan
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
            {code, title, desc, feeMonthly, feeInitial} = mapAll[k]
            unless code.match /^([a-zA-Z0-9-]+_){3}[0-9]+$/
              cb()
            else
              if k not in mapCached
                plan = new JRecurlyPlan
                plan.code = code
              else
                plan = mapAll[k]

              plan.title = title
              plan.desc = desc
              plan.feeMonthly = feeMonthly
              plan.feeInitial = feeInitial

              [prefix, category, item, version] = code.split '_'
              version = +version
              plan.product = {prefix, category, item, version}

              plan.lastUpdate = new Date()

              plan.save ->
                cb null, plan


        async = require 'async'
        async.parallel stack, (err, results)->
          callback()