{Base}  = require 'bongo'
recurly = require 'koding-payment'
{argv}  = require 'optimist'
KONFIG  = require('koding-config-manager').load("main.#{argv.c}")

module.exports = class JPayment extends Base

  {secure, dash, signature} = require 'bongo'
  {difference, extend} = require 'underscore'

  JUser = require '../user'

  @share()

  @set
    sharedEvents   :
      static       : []
      instance     : []
    sharedMethods  :
      static       :
        setPaymentInfo:
          (signature String, Object, Function)
        fetchTransactions:
          (signature Function)
        fetchCountryDataByIp:
          (signature String, Function)
        removePaymentMethod:
          (signature String, Function)

  @removePaymentMethod: secure (client, paymentMethodId, callback) ->
    (require './method').removePaymentMethod client, paymentMethodId, callback

  simple_recaptcha = require "simple-recaptcha"

  @isCaptchaValid = (ip, challenge, response, callback)->
    simple_recaptcha KONFIG.recaptcha, ip, challenge, response, (err)->
      if err
        return callback err

      callback null

  @setPaymentInfo = secure (client, paymentMethodId, data, callback) ->
    JSession = require '../session'
    JSession.one {clientId: client.sessionToken}, (err, session)=>
      return callback err  if err
      {username} = session

      if /guest-/.test username
        console.warn "ALERT: not logged in user is trying to add credit cards"
        return callback {message:"Not logged in"}

      {challenge, response} = data
      @isCaptchaValid session.clientIP, challenge, response, (err)->
        if err
          return callback {message:"Captcha failed, please try again."}

        delete data.challenge
        delete data.response

        [data, callback, paymentMethodId] = [paymentMethodId, data, callback]  unless callback
        (require './method').updatePaymentMethodById client, paymentMethodId, data, (err, response)->
          if err
            return callback {message:"We couldn't verify the information you entered, please try again."}

          callback err, response

  @fetchTransactions = secure ({ connection:{ delegate }}, callback) ->
    delegate.fetchPaymentMethods (err, paymentMethods) ->
      return callback err  if err
      return callback null, []  unless paymentMethods

      transactions = {}

      queue = paymentMethods.map (paymentMethod) -> ->
        { paymentMethodId } = paymentMethod

        recurly.fetchTransactions paymentMethodId, (err, transactionsList) ->
          transactions[paymentMethodId] = (transactionsList ? []).map \
            (transaction) ->
              transaction.invoice = (transaction.invoice?.split '/')?.pop()
              transaction

          queue.fin err

      dash queue, ->
        console.log transactions
        callback null, transactions

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
    console.error 'needs to be reimplemented'
#    {delegate} = client.connection
#    @getBalance_ (userCodeOf delegate), callback

  @fetchCountryDataByIp = (ip, callback)->
    countries = require './countries.json'
    {sortBy}  = require 'underscore'

    countries = {}
    countries[c.cca2] = {value: c.cca2, title: c.name}  for c in countries

    return callback null, { countries, countryOfIp: null }  unless ip

    geoIp = require 'node-freegeoip'
    geoIp.getLocation ip, (err, location)->
      callback err, {
        countries
        countryOfIp: unless err then location.country_code else null
      }

