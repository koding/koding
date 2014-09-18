Bongo = require "bongo"
{secure, signature, Base} = Bongo

module.exports = class Payment extends Base
  @share()

  @set
    classAttributes :
      bypassBatch     : yes

    sharedMethods     :
      static          :
        subscribe         :
          (signature Object, Function)
        unsubscribe       :
          (signature Object, Function)
        subscriptions     :
          (signature Object, Function)
        invoices          :
          (signature Object, Function)
        updateCreditCard  :
          (signature Object, Function)


  { bareRequest } = require "./helper"

  @subscribe = secure (client, data, callback)->
    data.accountId = getAccountId client
    bareRequest "paymentSubscribe", data, callback

  @unsubscribe = secure (client, data, callback)->
    data.accountId = getAccountId client
    bareRequest "paymentUnsubscribe", data, callback


  getAccountId = (client)->
    return client.connection.delegate.getId()
