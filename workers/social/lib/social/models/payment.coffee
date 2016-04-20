{ secure, signature, Base } = require 'bongo'
{ argv }    = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")
{ extend }  = require 'underscore'
KodingError = require '../error'

TEAM_PLANS  = require '../models/computeproviders/teamplans'

module.exports = class Payment extends Base
  @share()

  ERR_USER_NOT_CONFIRMED = 'ERR_USER_NOT_CONFIRMED'

  @set
    sharedMethods     :
      static          :
        subscribe         :
          (signature Object, Function)
        subscribeGroup    :
          (signature Object, Function)
        subscriptions     :
          (signature Object, Function)
        invoices          :
          (signature Object, Function)
        creditCard        :
          (signature Object, Function)
        fetchGroupCreditCard:
          (signature Function)
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
        fetchGroupPlan    :
          (signature Function)


  { get, post, deleteReq } = require './socialapi/requests'

  socialProxyUrl = '/api/social'


  @subscribe = secure (client, data, callback) ->
    requiredParams = [
      'token', 'email', 'planTitle', 'planInterval', 'provider'
    ]

    @canUserPurchase client, (err, confirmed) ->
      return callback err  if err
      return callback new KodingError ERR_USER_NOT_CONFIRMED  unless confirmed

      validateParams requiredParams, data, (err) ->
        return callback err  if err

        canChangePlan client, data.planTitle, (err) ->
          return callback err  if err

          data.accountId = getAccountId client
          url = "#{socialProxyUrl}/payments/subscribe"

          post url, data, (err, response) ->
            callback err, response

            data.status = if err then '$failed' else '$success'

            SiftScience = require './siftscience'
            SiftScience.transaction client, data, (err) ->
              console.warn 'logging to SiftScience failed', err  if err


  @subscribeGroup = (group, data, callback) ->

    return callback new KodingError 'No such group'  unless group

    if group.slug is 'koding' or KONFIG.environment is 'default'
      return callback null, {}

    requiredParams = ['token']
    validateParams requiredParams, data, (err) ->
      return callback err  if err

      # attach owner's email.
      # TODO: User should be able to choose their billing email. ~Umut
      group.fetchOwner (err, owner) ->
        return callback err  if err

        data = extend data,
          groupId: group._id
          email: owner.email
          provider: 'stripe'
          planTitle: 'team_base'
          planInterval: 'month'

        data.groupId = group._id
        url = "#{socialProxyUrl}/payments/group/subscribe"

        post url, data, callback


  @subscribeGroup$ = secure (client, data, callback) ->

    slug = client?.context?.group

    return callback new KodingError 'No such group'  unless slug

    JGroup = require './group'
    JGroup.one { slug }, (err, group) ->
      return callback err  if err
      Payment.subscribeGroup group, data, callback


  @fetchGroupPlan = (group, callback) ->

    return callback new KodingError 'No such group'  unless group

    if group.slug is 'koding' or KONFIG.environment is 'default'
      return callback null, { planTitle: 'unlimited' }

    url = "#{socialProxyUrl}/payments/group/subscriptions?group_id=#{group._id}"
    get url, {}, (err, subscription) ->
      return callback err  if err

      # unless isSubscriptionOk group, subscription
      #   return callback new KodingError 'Trial period exceeded'

      callback null, sanitizeSubscription subscription


  @fetchGroupPlan$ = secure (client, callback) ->

    slug = client?.context?.group

    return callback new KodingError 'No such group'  unless slug

    JGroup = require './group'
    JGroup.one { slug }, (err, group) ->
      return callback err  if err
      Payment.fetchGroupPlan group, callback


  @subscriptions$ = secure (client, data, callback) ->
    Payment.subscriptions client, data, callback

  @subscriptions = (client, data, callback) ->
    data.accountId = getAccountId client
    url = "#{socialProxyUrl}/payments/subscriptions?account_id=#{data.accountId}"

    get url, data, callback

  @invoices = secure (client, data, callback) ->
    data.accountId = getAccountId client
    url = "#{socialProxyUrl}/payments/invoices/#{data.accountId}"

    get url, data, callback

  @creditCard = secure (client, data, callback) ->
    data.accountId = getAccountId client
    url = "#{socialProxyUrl}/payments/creditcard/#{data.accountId}"

    get url, data, callback


  @fetchGroupCreditCard = (group, callback) ->

    return callback new KodingError 'No such group'  unless group

    data = { groupId: group._id }

    url = "#{socialProxyUrl}/payments/group/creditcard/#{data.groupId}"
    get url, data, callback


  @fetchGroupCreditCard$ = secure (client, callback) ->

    slug = client?.context?.group


    return callback new KodingError 'No such group'  unless slug

    JGroup = require './group'
    JGroup.one { slug }, (err, group) ->
      console.log {err, group}
      return callback err  if err
      Payment.fetchGroupCreditCard group, callback


  @updateCreditCard = secure (client, data, callback) ->
    requiredParams = [ 'token' , 'provider']

    validateParams requiredParams, data, (err) ->
      return callback err  if err

      data.accountId = getAccountId client
      url = "#{socialProxyUrl}/payments/creditcard/update"

      post url, data, callback

  @canChangePlan = secure (client, data, callback) ->
    requiredParams = [ 'planTitle' ]

    validateParams requiredParams, data, (err) ->
      return callback err  if err

      canChangePlan client, data.planTitle, callback

  @deleteAccount = (client, callback) ->
    accountId = getAccountId client
    url = "#{socialProxyUrl}/payments/customers/#{accountId}"

    deleteReq url, {}, callback

  @getToken = (data, callback) ->
    requiredParams = [ 'planTitle', 'planInterval' ]

    validateParams requiredParams, data, (err) ->
      return callback err  if err

      url = "#{socialProxyUrl}/payments/paypal/token"
      get url, data, callback


  @logOrder = secure (client, raw, callback) ->
    SiftScience = require './siftscience'
    SiftScience.createOrder client, raw, callback

  @canUserPurchase = secure (client, callback) ->
    { connection : { delegate } } = client

    unless delegate
      return callback new KodingError 'Account not found'

    if delegate.type isnt 'registered'
      return callback new KodingError 'guests are not allowed'

    delegate.fetchUser (err, user) ->
      return callback err  if err
      callback null, user.status is 'confirmed'

  validateParams = (requiredParams, data, callback) ->
    for param in requiredParams
      if not data[param]
        return callback new KodingError "#{param} is required"

    callback null

  getAccountId = (client) ->
    return client?.connection?.delegate?.getId()

  getUserName = (client) ->
    return client?.connection?.delegate?.profile?.nickname

  prettifyFeature = (name) ->
    switch name
      when 'alwaysOn'
        'alwaysOn vms'
      when 'storage'
        'GB storage'
      when 'total'
        'total vms'
      when 'snapshots'
        'total snapshots'

  canChangePlan = (client, planTitle, callback) ->
    fetchPlan client, planTitle, (err, plan) ->
      return callback err  if err

      fetchUsage client, (err, usage) ->
        return callback err  if err

        for name in ['alwaysOn', 'storage', 'total', 'snapshots']
          if usage[name] > plan[name]
            return callback {
              'message'   : "Sorry, your request to downgrade can't be processed because you are currently using more resources than the plan you are trying to downgrade to allows."
              'allowed'   : plan[name]
              'usage'     : usage[name]
              'planTitle' : planTitle
              'name'      : prettifyFeature name
            }

        callback null

  fetchUsage = (client, callback) ->
    ComputeProvider = require './computeproviders/computeprovider'
    ComputeProvider.fetchUsage client, { provider: 'koding' }, callback

  fetchPlan = (client, planTitle, callback) ->

    plans   = require './computeproviders/plans'

    return callback new KodingError 'plan not found'  unless plans[planTitle]

    { clone } = require 'underscore'
    plan    = clone plans[planTitle]

    fetchReferrerSpace client, (err, space) ->
      return callback err  if err

      plan.storage += space

      callback null, plan

  fetchReferrerSpace = (client, callback) ->
    originId = client.connection.delegate.getId()

    JReward = require './rewards'
    options = { unit: 'MB', type: 'disk', originId }

    JReward.fetchEarnedAmount options, (err, amount) ->
      return callback err  if err?
      callback null, amount / 1000


  isSubscriptionOk = (group, subscription) ->

    return yes  unless subscription.planTitle is 'free'

    # returns a date object from ObjectId
    groupCreationDay = group._id.getTimestamp()
    today = new Date

    # how many days a trial period is for.
    trialRestrictions = TEAM_PLANS['trial']
    { validFor } = trialRestrictions

    return dateDiffInDays(today, groupCreationDay) < validFor


  sanitizeSubscription = (subscription) ->

    return subscription  unless subscription.planTitle is 'free'

    return extend subscription, { planTitle: 'trial' }


  dateDiffInDays = (a, b) ->

    MILLISECONDS_PER_DAY = 1000 * 60 * 60 * 24

    a = Date.UTC(a.getFullYear(), a.getMonth(), a.getDate())
    b = Date.UTC(b.getFullYear(), b.getMonth(), b.getDate())

    return Math.floor((a - b) / MILLISECONDS_PER_DAY)


