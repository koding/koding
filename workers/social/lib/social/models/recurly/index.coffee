jraphical = require 'jraphical'
JUser = require '../user'
payment = require 'koding-payment'

forceRefresh = yes

module.exports = class JRecurlyPlan extends jraphical.Module

  {secure} = require 'bongo'

  JRecurlyToken = require './token'
  JRecurlySubscription = require './subscription'

  @share()

  @set
    indexes:
      code         : 'unique'
    sharedMethods  :
      static       : [
        'getPlans',
        'setUserAccount', 'getUserAccount', 'getUserTransactions'
      ]
      instance     : [
        'getToken', 'subscribe'
      ]
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

  @setUserAccount = secure (client, data, callback)->
    {delegate}    = client.connection

    data.username  = delegate.profile.nickname 
    data.ipAddress = '0.0.0.0'
    data.firstName = delegate.profile.firstName
    data.lastName  = delegate.profile.lastName

    JUser.fetchUser client, (e, r) ->
      data.email = r.email
      payment.setAccount "user_#{delegate._id}", data, callback

  @getUserAccount = secure (client, callback)->
    {delegate}    = client.connection
    payment.getAccount "user_#{delegate._id}", callback

  @getUserTransactions = secure (client, callback)->
    {delegate}    = client.connection
    payment.getUserTransactions "user_#{delegate._id}", callback

  @getPlans = secure (client, filter..., callback)->
    [prefix, category, item] = filter
    selector = {}
    selector["product.prefix"] = prefix  if prefix
    selector["product.category"] = category  if category
    selector["product.item"] = item  if item

    unless forceRefresh
      JRecurlyPlan.all selector, callback
    else
      JRecurlyPlan.one {}, (err, plan)=>
        callback err  if err
        unless plan
          @updateCache -> JRecurlyPlan.all selector, callback
        else
          plan.lastUpdate ?= 0
          now = (new Date()).getTime()
          if now - plan.lastUpdate > 1000 * 60 * 2
            @updateCache -> JRecurlyPlan.all selector, callback
          else
            JRecurlyPlan.all selector, callback

  # Recurly web hook will use this method to invalidate the cache.
  @updateCache = (callback)->
    console.log "Updating Recurly plans..."

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
              if k not in Object.keys(mapCached)
                plan = new JRecurlyPlan
                plan.code = code
              else
                plan = mapCached[k]

              plan.title = title
              plan.desc = desc
              plan.feeMonthly = feeMonthly
              plan.feeInitial = feeInitial

              [prefix, category, item, version] = code.split '_'
              version = +version
              plan.product = {prefix, category, item, version}

              plan.lastUpdate = (new Date()).getTime()

              plan.save ->
                cb null, plan

        async = require 'async'
        async.parallel stack, (err, results)->
          callback()

  getToken: secure (client, callback)->
    {delegate} = client.connection
    JRecurlyToken.createToken client,
      planCode: @code
    , callback

  subscribe: secure (client, data, callback)->
    {delegate} = client.connection
    data.quantity ?= 1
    JRecurlyToken.checkToken client, {planCode: @code, pin: data.pin}, (status)=>
      unless status
        callback yes, {}
      else
        payment.addUserSubscription "user_#{delegate._id}",
          plan     : @code
          quantity : data.quantity
        , (err, result)->
          return callback err  if err
          sub = new JRecurlySubscription
            planCode : result.code
            userCode : "user_#{delegate._id}"
            uuid     : result.uuid
            quantity : result.quantity
            status   : result.status
            datetime : result.datetime
            expires  : result.expires
            renew    : result.renew
          sub.save ->
            callback no, sub