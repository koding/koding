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


  { doRequest } = require "./helper"

  @subscribe = secure (client, data, callback)->
    data.accountId = getAccountId client
    doRequest "paymentSubscribe", client, data, callback

  @unsubscribe = secure (client, data, callback)->
    data.accountId = getAccountId client
    doRequest "paymentUnsubscribe", client, data, callback


  getAccountId = (client)-> client.connection.delegate.getId()
