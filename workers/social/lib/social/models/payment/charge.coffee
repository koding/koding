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
      uuid            : 'unique'
    sharedMethods     :
      static          : [
        # TODO: this is a really big WTF, and needs to be removed:
        'all'
        'one'
        'some'
        'charge'
        'fetchToken'
        'fetchCharges'
      ]
      instance        : [
        'cancel'
      ]
    schema            :
      uuid            : String
      paymentMethodId : String
      amount          : Number
      status          : String
      lastUpdate      : Number

  @fetchCharges = secure (client, callback)->
    callback { message: 'Not implemented!' }

  @updateCache = (selector, callback)->
    JPayment.updateCache
      constructor   : this
      selector      : selector
      method        : 'fetchTransactions'
      methodOptions : selector.paymentMethodId
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

  @fetchToken = secure (client, data, callback)->
    callback { message: 'Not implemented!' }

  @charge = secure (client, data, callback)->
    { connection: { delegate } } = client
    
    { paymentMethodId, description, feeAmount } = data

    (require './method').one { paymentMethodId }, (err, method) =>
      return callback err  if err
      return callback {
        message: "Unknown payment method! #{paymentMethodId}"
      }  unless method?

      delegate.hasTarget method, 'payment method', (err, hasTarget) =>
        return callback err  if err
        return callback {
          message: 'You are not authorized to use this payment method!'
        }  unless hasTarget

        recurly.createTransaction paymentMethodId,
          amount  : feeAmount
          desc    : description
        , (err, transaction) =>
          return callback err  if err

          charge = new this {
            uuid: transaction.uuid
            paymentMethodId
            amount: feeAmount
            status: transaction.status
          }
          charge.save (err) ->
            return callback err  if err

            callback null, charge
    # {delegate} = client.connection
    # userCode = "user_#{delegate._id}"

    # JPaymentToken.checkToken client,
    #   planCode: "charge_#{data.planCode}_#{data.amount}"
    #   pin: data.pin
    # , (err)=>
    #   return callback err  if err
    #   {amount, desc} = data

    #   recurly.createTransaction userCode, {amount, desc}, (err, charge)=>
    #     return callback err  if err
    #     {uuid, amount, status} = charge

    #     pay = new JPaymentCharge {uuid, userCode, amount, status}
    #     pay.save (err)->
    #       console.log 'transaction created', arguments
    #       callback err, unless err then pay

  cancel: secure ({ connection:{ client } }, callback)->
    recurly.deleteTransaction @paymentMethodId, {@uuid, @amount},
      (err, charge) =>
        return callback err  if err

        @status = charge.status
        @save (err)-> callback err, this
