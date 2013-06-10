jraphical = require 'jraphical'
JUser = require '../user'
payment = require 'koding-payment'

forceRefresh  = yes
forceInterval = 60 * 5

module.exports = class JRecurlyCharge extends jraphical.Module

  {secure} = require 'bongo'
  
  JRecurlyToken = require './token'

  @share()

  @set
    indexes:
      uuid         : 'unique'
    sharedMethods  :
      static       : [
        'all', 'one', 'some',
        'getToken', 'charge', 'getCharges'
      ]
      instance     : [
        'cancel'
      ]
    schema         :
      uuid         : String
      userCode     : String
      amount       : Number
      status       : String
      lastUpdate   : Number

  @getCharges = secure (client, callback)->
    {delegate} = client.connection
    selector =
      userCode : "user_#{delegate._id}"

    unless forceRefresh
      JRecurlyCharge.all selector, callback
    else
      JRecurlyCharge.one {}, (err, charge)=>
        callback err  if err
        unless charge
          @updateCache client, -> JRecurlyCharge.all selector, callback
        else
          charge.lastUpdate ?= 0
          now = (new Date()).getTime()
          if now - charge.lastUpdate > 1000 * forceInterval
            @updateCache client, -> JRecurlyCharge.all selector, callback
          else
            JRecurlyCharge.all selector, callback

  # Recurly web hook will use this method to invalidate the cache.
  @updateCache = secure (client, callback)->
    console.log "Updating Recurly user transactions..."
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"

    payment.getUserTransactions userCode, (err, allCharges)->
      mapAll = {}
      allCharges.forEach (rCharge)->
        if rCharge.source is 'transaction'
          mapAll[rCharge.uuid] = rCharge
      JRecurlyCharge.all {userCode}, (err, cachedPlans)->
        mapCached = {}
        cachedPlans.forEach (cCharge)->
          mapCached[cCharge.uuid] = cCharge
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
            {uuid, amount, status} = mapAll[k]
            if k not in Object.keys(mapCached)
              charge = new JRecurlyCharge
              charge.uuid = uuid
            else
              charge = mapCached[k]

            charge.userCode = userCode
            charge.amount   = amount
            charge.status   = status

            charge.lastUpdate = (new Date()).getTime()

            charge.save ->
              cb null, charge

        async = require 'async'
        async.parallel stack, (err, results)->
          callback()

  @getToken = secure (client, data, callback)->
    {delegate} = client.connection
    JRecurlyToken.createToken client,
      planCode: "charge_#{data.code}_#{data.amount}"
    , callback

  @charge = secure (client, data, callback)->
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"
    JRecurlyToken.checkToken client,
      planCode: "charge_#{data.code}_#{data.amount}"
      pin: data.pin
    , (status)=>
      unless status
        callback yes, {}
      else
        payment.addUserTransaction userCode,
          amount         : data.amount
        , (err, charge)=>
          return callback err  if err
          pay = new JRecurlyCharge
            uuid       : charge.uuid
            amount     : charge.amount
            userCode   : userCode
            status     : charge.status
          pay.save ->
            console.log arguments
            callback no, pay

  cancel: secure (client, callback)->
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"
    payment.deleteUserTransaction userCode,
      uuid   : @uuid
      amount : @amount
    , (err, charge)=>
      return callback yes  if err
      @status   = charge.status
      @save =>
        callback no, @