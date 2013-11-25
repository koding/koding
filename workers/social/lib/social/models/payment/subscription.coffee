jraphical = require 'jraphical'
payment   = require 'koding-payment'

forceRefresh  = yes
forceInterval = 60 * 3

module.exports = class JPaymentSubscription extends jraphical.Module

  {secure, dash} = require 'bongo'
  {partition} = require '../../util'
  JUser    = require '../user'
  JPayment = require './index'

  @share()

  @set
    indexes         :
      uuid          : 'unique'
    sharedMethods   :
      static        : [
        'fetchUserSubscriptions'
        'fetchUserSubscriptionsWithPlan'
        'checkUserSubscription'
      ]
      instance      : [
        'cancel'
        'resume'
        'calculateRefund'
        'checkUsage'
        'debit'
        'credit'
      ]
    schema          :
      uuid          : String
      planCode      : String
      userCode      : String
      quantity      :
        type        : Number
        default     : 1
      status        :
        type        : String
        enum        : ['Unknown status!'
                      [
                        'active'
                        'canceled'
                        'expired'
                        'future'
                        'in_trial'
                        'live'
                        'past_due'
                      ]]
      activatedAt   : Date
      expiresAt     : Date
      renewAt       : Date
      feeAmount     : Number
      lastUpdate    : Number
      usage         :
        type        : Object # "usage" is designed to mirror "quantities" from JPaymentPlan
        default     : {}
      tags          : (require './schema').tags

  @fetchUserSubscriptions = secure ({ connection:{ delegate }}, callback) ->
    delegate.fetchPaymentMethods (err, paymentMethods) =>
      return callback err  if err
      subscriptions = {}
      queue = paymentMethods.map ({ paymentMethodId }) => =>
        @fetchSubscriptions paymentMethodId, (err, subs) ->
          return queue.fin err  if err
          subscriptions[paymentMethodId] = subs  if subs.length
          queue.fin()
      dash queue, -> callback null, subscriptions

  @fetchUserSubscriptionsWithPlan = secure (client, callback)->
    @fetchUserSubscriptions client, (err, subs)->
      return callback err      if err
      return callback null, [] unless subs

      planCode = $in: (sub.planCode for sub in subs)
      JPaymentPlan = require './plan'
      JPaymentPlan.some { planCode }, {}, (err, plans)->
        return callback err  if err
        planMap = {}
        planMap[plan.planCode] = plan  for plan in plans
        sub.plan = planMap[sub.planCode]  for sub in subs

        callback null, subs

  @checkUserSubscription = secure ({connection:{delegate}}, planCode, callback)->
    @fetchAllSubscriptions {
      planCode
      $or: [
        {status: 'active'}
        {status: 'canceled'}
      ]
    }, callback

  @fetchSubscriptions = (selector, callback) ->
    selector = { paymentMethodId: selector }  if 'string' is typeof selector
    @fetchAllSubscriptions selector, callback

  @fetchAllSubscriptions = (selector, callback) ->
    

  refund: (percent, callback)->
    JPaymentPlan = require './plan'
    JPaymentPlan.fetchPlanByCode @planCode, (err, plan) =>
      return callback err  if err
      payment.addUserCharge @userCode,
        amount: -1 * plan.feeAmount * percent / 100
      , callback

  calculateRefund: (callback)->
    aDay = 1000 * 60 * 60 * 24
    refundMap = [
      {uplimit: aDay * 1,  percent: 90}
      {uplimit: aDay * 7,  percent: 40}
      {uplimit: aDay * 15, percent: 20}
    ]

    dateNow = new Date
    dateEnd = @renewAt
    usage   = (dateEnd - dateNow) / aDay

    refundMap.every (ref)=>
      return callback null, ref.percent  if usage < ref.uplimit
      callback yes, 0

  # terminate: (callback)->
  #   payment.terminateSubscription @userCode, {@uuid, refund : 'none'}, (err, sub)=>
  #     return callback err  if err

  #     @calculateRefund (err, percent)=>
  #       unless err
  #         @refund percent, ->
  #           console.log "Refunding #{percent}% of subscription #{@uuid}."

  #     update_ sub, callback

  updateStatus: (status, callback) ->
    @update $set: { status }, callback

  invokeMethod: (method, options, callback) ->
    [callback, options] = [options, callback]  unless callback
    options ?= { @uuid }
    payment[method] options, (err, sub) =>
      return callback err  if err

      @updateStatus sub.status, (err) ->
        return callback err  if err

        callback null

  cancel: (callback) ->
    @invokeMethod 'cancelSubscription', callback

  terminate: (callback) ->
    @invokeMethod 'terminateSubscription', (err) ->
      return callback err  if err

      callback null  # dunno why we're calling bacjk early C.T.

      @calculateRefund (err, percent)=>
        unless err
          @refund percent, (err) ->
            console.error err  if err
            console.log "Refunding #{percent}% of subscription #{@uuid}."

  resume: (callback) ->
    @invokeMethod 'reactivateSubscription', callback

  checkUsage: (product, callback) ->
    JPaymentPlan = require './plan'

    { quantities } = product

    unless quantities?
      quantities = {}
      quantities[product.planCode] = 1

    JPaymentPlan.fetchPlanByCode @planCode, (err, plan) =>
      return callback err  if err
      return callback { message: 'unknown plan code', @planCode }  unless plan

      usages = for own planCode, quantity of quantities
        planSize = plan.quantities[planCode]
        usageAmount = @usage[planCode] ? 0
        spendAmount = product.quantities[planCode] ? 0

        total = planSize - usageAmount - spendAmount

        { planCode, total }

      [ok, over] = partition usages, ({ total }) -> total >= 0

      if over.length > 0
      then callback { message: 'quota exceeded', ok, over }
      else callback null

  createFulfillmentNonce: ({ planCode }, isDebit, callback) ->
    JFulfillmentNonce = require './nonce'

    nonce = new JFulfillmentNonce {
      planCode
      subscriptionCode: @planCode
      action: if isDebit then 'debit' else 'credit'
    }

    nonce.save (err) ->
      return callback err  if err

      callback null, nonce.nonce

  debit: (pack, callback, multiplyFactor = 1) ->
    @checkUsage pack, (err, usage) =>
      return callback err  if err

      { quantities } = pack

      op = $set: (Object.keys quantities)
        .reduce( (memo, key) =>
          memo["usage.#{ key }"] =
            (@usage[key] ? 0) + quantities[key] * multiplyFactor
          memo
        , {})

      @update op, (err) =>
        return callback err  if err

        @createFulfillmentNonce pack, (multiplyFactor > 0), callback

  debit$: secure (client, pack, callback, multiplyFactor) ->
    JPaymentPlan = require './plan'

    { delegate } = client.connection

    delegate.hasTarget this, 'service subscription', (err, hasTarget) =>
      return callback err  if err
      return callback { message: 'Access denied!' }  unless hasTarget

      @debit pack, callback, multiplyFactor

  credit$: secure (client, pack, callback) ->
    @debit$ client, pack, callback, -1
