{Base}  = require 'bongo'
recurly = require 'koding-payment'

module.exports = class JPayment extends Base

  {secure, dash} = require 'bongo'
  {difference, extend} = require 'underscore'

  JUser = require '../user'

  @share()

  @set
    sharedMethods  :
      static       : [
        'getBalance'
        'setPaymentInfo'
        'fetchAccountDetails'
        'fetchTransactions'
        'fetchCountryDataByIp'
        'removePaymentMethod'
      ]

  @removePaymentMethod: secure (client, paymentMethodId, callback) ->
    (require './method').removePaymentMethod client, paymentMethodId, callback

  @setPaymentInfo = secure (client, paymentMethodId, data, callback) ->
    [data, callback, paymentMethodId] = [paymentMethodId, data, callback]  unless callback
    (require './method').updatePaymentMethodById client, paymentMethodId, data, callback

  @fetchAccountDetails = secure ({ connection:{ delegate }}, callback)->
    throw Error 'needs to be reimplemented'
#    recurly.fetchAccountDetailsByPaymentMethodId (userCodeOf delegate), callback

  @fetchTransactions = secure ({ connection:{ delegate }}, callback) ->
    throw Error 'needs to be reimplemented'
#    recurly.fetchTransactions (userCodeOf delegate), callback 

  @fetchAccount = secure (client, callback) ->
    {delegate} = client.connection
    delegate.fetchUser (err, user) ->
      return callback err  if err?
      {username, firstName, lastName} = delegate.profile
      callback null, {
        email: user.email
        username
        firstName
        lastName
      }

  @getBalance_ = (account, callback) ->
    recurly.fetchTransactions account, (err, adjs) ->
      return callback err  if err?
      spent = 0
      adjs.forEach (adj) ->
        spent += parseInt adj.amount, 10  if adj.status is 'success'

      recurly.fetchAdjustments account, (err, adjs) ->
        charged = 0
        adjs.forEach (adj) ->
          charged += parseInt adj.amount, 10

        callback null, spent - charged

  @getBalance = secure (client, callback)->
    throw Error 'needs to be reimplemented'
#    {delegate} = client.connection
#    @getBalance_ (userCodeOf delegate), callback

  @invalidateCacheAndLoad: (constructor, selector, options, callback)->
    cb = -> constructor.all selector, callback
    return cb()  unless options.forceRefresh

    constructor.one selector, sort:lastUpdate:1, (err, obj)=>
      return constructor.updateCache selector, cb  if err or not obj
      obj.lastUpdate ?= 0
      now = Date.now()
      if now - obj.lastUpdate > 1000 * options.forceInterval
        constructor.updateCache selector, cb
      else
        cb()

  @updateCache = (options, callback)->
    {constructor, selector, method, methodOptions, keyField, message, forEach} = options
    selector ?= {}

    console.log "Updating #{message}..."

    cb = (err, objs) ->
      return callback err  if err

      all = {}
      all[obj[keyField]] = obj  for obj in objs

      constructor.all selector, (err, cachedObjs) ->

        return callback err  if err

        cached = {}
        cached[cObj[keyField]] = cObj  for cObj in cachedObjs

        keys    = all: Object.keys(all), cached: Object.keys(cached)
        stackCb = (err) ->
          if err
          then callback err
          else stack.fin()

        stack =  keys.all.map (k) -> ->
          forEach k, cached[k], all[k], stackCb

        # remove obsolete plans in mongo
        difference(keys.cached, keys.all).forEach (k) ->
          stack.push -> cached[k].remove stackCb

        # create new JPaymentPlan models for new plans from Recurly
        difference(keys.all, keys.cached).forEach (k) ->
          cached[k] = new constructor
          cached[k][keyField] = all[k][keyField]

        dash stack, ->
          console.log "Updated #{message}!"
          callback()

    if methodOptions
    then recurly[method] methodOptions, cb
    else recurly[method] cb

  @fetchCountryDataByIp = (ip, callback)->
    countries = require './countries.json'
    {sortBy}  = require 'underscore'

    data = {}
    data[c.cca2] = {value: c.cca2, title: c.name}  for c in countries

    return callback null, data, null  unless ip

    geoIp = require 'node-freegeoip'
    geoIp.getLocation ip, (err, location)->
      callback err, data, unless err then location.country_code else null
