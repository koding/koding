Bongo = require "bongo"
{secure, signature, Base} = Bongo

module.exports = class Payment extends Base
  @share()

  @set
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
        canChangePlan     :
          (signature Object, Function)


  { get, post } = require "./socialapi/requests"

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

  @canChangePlan = secure (client, data, callback)->
    requiredParams = [ "planTitle" ]

    validateParams requiredParams, data, (err)->
      canChangePlan client, data.planTitle, callback


  validateParams = (requiredParams, data, callback)->
    for param in requiredParams
      if not data[param]
        return callback {message: "#{param} is required"}

    callback null

  getAccountId = (client)->
    return client.connection.delegate.getId()

  prettifyFeature = (name)->
    switch name
      when "alwaysOn"
        "alwaysOn vms"
      when "storage"
        "GB storage"
      when "total"
        "total vms"

  canChangePlan = (client, planTitle, callback)->
    fetchPlan client, planTitle, (err, plan)->
      return callback err  if err

      fetchUsage client, (err, usage)->
        return callback err  if err

        for name in ["alwaysOn", "storage", "total"]
          if usage[name] > 0
            return callback {
              "message"   : "Can't change plan due to excessive resource usage",
              "allowed"   : plan[name]
              "usage"     : usage[name]
              "planTitle" : planTitle
              "name"      : prettifyFeature name
            }

        callback null

  fetchUsage = (client, callback)->
    ComputeProvider = require "./computeproviders/computeprovider"
    ComputeProvider.fetchUsage client, {
      provider   : "koding"
      credential : client.connection.delegate.profile.nickname
    }, callback

  fetchPlan = (client, planTitle, callback)->
    ComputeProvider = require "./computeproviders/computeprovider"
    ComputeProvider.fetchPlans client,
      provider   : "koding"
    , (err, plans)->
      return err  if err

      plan = plans[planTitle]
      return callback {"message" : "plan not found"}  unless plan

      fetchReferrerSpace client, (err, space)->
        return callback err  if err

        plan.storage += space

        callback null, plan

  fetchReferrerSpace = (client, callback)->
    JReferral = require "./referral/index"
    JReferral.fetchEarnedSpace client, callback
