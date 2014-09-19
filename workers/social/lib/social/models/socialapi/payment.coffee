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


  { get, post } = require "./requests"

  @subscribe = secure (client, data, callback)->
    data.accountId = getAccountId client
    requiredParams = [
      "accountId", "token", "email", "planTitle", "planInterval", "provider"
    ]

    for param in requiredParams
      if not data[param]
        return callback {message: "#{param} is required"}

    url = "/payments/subscribe"
    post url, data, callback

  @unsubscribe = secure (client, data, callback)->
    data.accountId = getAccountId client
    requiredParams = [
      "accountId", "plan", "provider"
    ]

    for param in requiredParams
      if not data[param]
        return callback {message: "#{param} is required"}

    url = "/payments/unsubscribe"
    post url, data, callback

  @subscriptions = secure (client, data, callback)->
    data.accountId = getAccountId client
    url = "/payments/subscriptions/#{data.accountId}"

    get url, data, callback


  getAccountId = (client)->
    return client.connection.delegate.getId()
