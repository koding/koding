jraphical = require 'jraphical'
recurly   = require 'koding-payment'

forceRefresh  = yes
forceInterval = 60 * 3

module.exports = class JPaymentCharge extends jraphical.Module

  {secure, signature}      = require 'bongo'
  JPayment      = require './token'
  JPaymentToken = require './token'
  JUser         = require '../user'

  @share()

  @set
    indexes:
      uuid            : 'unique'
    sharedEvents      :
      static          : []
      instance        : []
    sharedMethods     :
      static          :
        # TODO: this is a really big WTF, and needs to be removed:
        # 'all'
        one:
          (signature Object, Function)
        some:
          (signature Object, Object, Function)
        charge:
          (signature Object, Function)

      instance:
        cancel:
          (signature Function)

    schema            :
      uuid            : String
      paymentMethodId : String
      amount          : Number
      status          : String
      lastUpdate      : Number

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
