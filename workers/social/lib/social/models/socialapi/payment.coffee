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
        subscriptions     :
          (signature Object, Function)
        invoices          :
          (signature Object, Function)
        creditCard        :
          (signature Object, Function)
        updateCreditCard  :
          (signature Object, Function)


  { get, post } = require "./requests"

  @subscribe = secure (client, data, callback)->
    requiredParams = [
      "token", "email", "planTitle", "planInterval", "provider"
    ]

    validateParams requiredParams, data, (err)->
      return callback err  if err

      canChangeplan client, data.planTitle, (err)->
        return callback err  if err

        data.accountId = getAccountId client
        url = "/payments/subscribe"

        post url, data, callback

  @subscriptions = secure (client, data, callback)->
    data.accountId = getAccountId client
    url = "/payments/subscriptions/#{data.accountId}"

    get url, data, callback

  @invoices = secure (client, data, callback)->
    data.accountId = getAccountId client
    url = "/payments/invoices/#{data.accountId}"

    get url, data, callback

  @creditCard = secure (client, data, callback)->
    data.accountId = getAccountId client
    url = "/payments/creditcard/#{data.accountId}"

    get url, data, callback

  @updateCreditCard = secure (client, data, callback)->
    requiredParams = [ "token" , "provider"]

    validateParams requiredParams, data, (err)->
      return callback err  if err

      data.accountId = getAccountId client
      url = "/payments/creditcard/update"

      post url, data, callback


  validateParams = (requiredParams, data, callback)->
    for param in requiredParams
      if not data[param]
        return callback {message: "#{param} is required"}

    callback null

  getAccountId = (client)->
    return client.connection.delegate.getId()

  canChangeplan = (client, planTitle, callback)->
    fetchPlan client, planTitle, (err, plan)->
      return callback err  if err

      fetchUsage client, (err, usage)->
        return callback err  if err

        for name in ["alwaysOn", "storage", "total"]
          if usage[name] > plan[name]
            return callback {"message" : "
              You can't change to '#{planTitle}' plan since you're
              current using #{usage[name]} #{name}. The new plan only
              allows #{plan[name]} #{name}."
            }

        callback null

  fetchUsage = (client, callback)->
    ComputeProvider = require "../computeproviders/computeprovider"
    ComputeProvider.fetchUsage client, {
      provider   : "koding"
      credential : client.connection.delegate.profile.nickname
    }, callback

  fetchPlan = (client, planTitle, callback)->
    ComputeProvider = require "../computeproviders/computeprovider"
    ComputeProvider.fetchPlans client,
      provider   : "koding"
    , (err, plans)->
      return err  if err

      plan = plans[planTitle]
      return callback {"message" : "plan not found"}  unless plan

      callback null, plan

