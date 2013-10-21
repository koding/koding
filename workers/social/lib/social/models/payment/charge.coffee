jraphical = require 'jraphical'
recurly   = require 'koding-payment'

forceRefresh  = yes
forceInterval = 60 * 3

module.exports = class JPaymentCharge extends jraphical.Module

  {secure}      = require 'bongo'
  JPayment      = require './token'
  JPaymentToken = require './token'
  JUser         = require '../user'

  @share()

  @set
    indexes:
      uuid         : 'unique'
    sharedMethods  :
      static       : [
        'all', 'one', 'some',
        'getToken', 'charge', 'getCharges'
      ]
      instance     : ['cancel']
    schema         :
      uuid         : String
      userCode     : String
      amount       : Number
      status       : String
      lastUpdate   : Number

  @getCharges = secure (client, callback)->
    {delegate} = client.connection
    selector = userCode : "user_#{delegate._id}"

    JPayment.invalidateCacheAndLoad this, selector, {forceRefresh, forceInterval}, callback

  @updateCache = (selector, callback)->
    JPayment.updateCache
      constructor   : this
      selector      : selector
      method        : 'fetchTransactions'
      methodOptions : selector.accountCode
      keyField      : 'uuid'
      message       : 'user transactions'
      forEach       : (k, cached, transaction, stackCb)->
        {uuid, amount, status} = transaction

        charge.setData extend charge.getData(), {
          paymentMethodId: selector.paymentMethodId
          amount
          status
        }
        charge.lastUpdate = Date.now()
        charge.save stackCb
    , callback

  @getToken = secure (client, data, callback)->
    {delegate} = client.connection
    JPaymentToken.createToken client,
      planCode: "charge_#{data.code}_#{data.amount}"
    , callback

  @charge = secure (client, data, callback)->
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"

    JPaymentToken.checkToken client,
      planCode: "charge_#{data.code}_#{data.amount}"
      pin: data.pin
    , (err)=>
      return callback err  if err
      {amount, desc} = data

      recurly.createTransaction userCode, {amount, desc}, (err, charge)=>
        return callback err  if err
        {uuid, amount, status} = charge

        pay = new JPaymentCharge {uuid, userCode, amount, status}
        pay.save (err)->
          console.log 'transaction created', arguments
          callback err, unless err then pay

  cancel: secure ({connection:{client}}, callback)->
    userCode = "user_#{delegate._id}"
    recurly.deleteTransaction userCode, {@uuid, @amount}, (err, charge)=>
      return callback err  if err

      @status = charge.status
      @save (err)-> callback err, this
