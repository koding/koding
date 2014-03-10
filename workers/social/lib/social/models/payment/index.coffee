{Base}  = require 'bongo'
recurly = require 'koding-payment'

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

  @setPaymentInfo = secure (client, paymentMethodId, data, callback) ->
    [data, callback, paymentMethodId] = [paymentMethodId, data, callback]  unless callback
    (require './method').updatePaymentMethodById client, paymentMethodId, data, callback

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

    data = {}
    data[c.cca2] = {value: c.cca2, title: c.name}  for c in countries

    return callback null, data, null  unless ip

    geoIp = require 'node-freegeoip'
    geoIp.getLocation ip, (err, location)->
      callback err, data, unless err then location.country_code else null
