Bongo = require "bongo"
{secure, signature, Base} = Bongo

module.exports = class Payment extends Base
  @share()

  ERR_USER_NOT_CONFIRMED = 'ERR_USER_NOT_CONFIRMED'

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
        logOrder          :
          (signature Object, Function)
        getToken          :
          (signature Object, Function)
        canUserPurchase   :
          (signature Function)


  { get, post, deleteReq } = require "./socialapi/requests"


  @subscribe = secure (client, data, callback)->
    requiredParams = [
      "token", "email", "planTitle", "planInterval", "provider"
    ]

    @canUserPurchase client, (err, confirmed) ->
      return callback err  if err
      return callback { message: ERR_USER_NOT_CONFIRMED }  unless confirmed

      validateParams requiredParams, data, (err)->
        return callback err  if err

        canChangePlan client, data.planTitle, (err)->
          return callback err  if err

          data.accountId = getAccountId client
          url = "/payments/subscribe"

          post url, data, (err, response)->
            callback err, response

            data.status = if err then "$failed" else "$success"

            SiftScience = require "./siftscience"
            SiftScience.transaction client, data, (err)->
              log "logging to SiftScience failed", err  if err


  @subscriptions$ = secure (client, data, callback)->
    Payment.subscriptions client, data, callback

  @subscriptions = (client, data, callback)->
    data.accountId = getAccountId client
    url = "/payments/subscriptions?account_id=#{data.accountId}"

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
      return callback err  if err

      canChangePlan client, data.planTitle, callback

  @deleteAccount = (client, callback)->
    accountId = getAccountId client
    url = "/payments/customers/#{accountId}"

    deleteReq url, {}, callback

  @getToken = (data, callback)->
    requiredParams = [ "planTitle", "planInterval" ]

    validateParams requiredParams, data, (err)->
      return callback err  if err

      url = "/payments/paypal/token"
      get url, data, callback


  @logOrder = secure (client, raw, callback)->
    SiftScience = require "./siftscience"
    SiftScience.createOrder client, raw, callback

  @canUserPurchase = secure (client, callback)->
    {connection : {delegate}} = client

    if delegate.type isnt "registered"
      return callback {message:"guests are not allowed"}

    delegate.fetchUser (err, user)->
      return callback err  if err
      callback null, user.status is "confirmed"

  validateParams = (requiredParams, data, callback)->
    for param in requiredParams
      if not data[param]
        return callback {message: "#{param} is required"}

    callback null

  getAccountId = (client)->
    return client.connection.delegate.getId()

  getUserName = (client)->
    return client.connection.delegate.profile.nickname

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
          if usage[name] > plan[name]
            return callback {
              "message"   : "Sorry, your request to downgrade can't be processed because you are currently using more resources than the plan you are trying to downgrade to allows."
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
    originId = client.connection.delegate.getId()

    JReward = require './rewards'
    options = { unit: 'MB', type: 'disk', originId }

    JReward.fetchEarnedAmount options, (err, amount)->
      return callback err  if err?
      callback null, amount / 1000
