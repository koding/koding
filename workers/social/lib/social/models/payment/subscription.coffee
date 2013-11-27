jraphical = require 'jraphical'
payment   = require 'koding-payment'

forceRefresh  = yes
forceInterval = 60 * 3

module.exports = class JPaymentSubscription extends jraphical.Module

  {secure, dash} = require 'bongo'
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
        'transitionTo'
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
      paymentMethodId: String
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
    throw Error 'reimplement this!'

  isOwnedBy: (account, callback) ->
    account.hasTarget this, 'service subscription', callback

  refund: (options, callback) ->
    payment.createRefund @paymentMethodId, options, callback

  calculateRefund: ->
    { max, ceil } = Math

    now     = Date.now()
    begin   = +@activatedAt
    end     = max +(@renewAt ? 0), +(@expiresAt ? 0)
    usage   = (now - begin) / (end - begin)
    ratio   = (100 - (usage * 100)) / 100

    return ceil ratio * @feeAmount # cents

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

  terminate: (oldPlan, callback, applyRefund = yes) ->
    @invokeMethod 'terminateSubscription', (err) =>
      return callback err  if err
      amount = @calculateRefund()
      description =
        """
        Credit — #{ oldPlan.title }
        """

      if applyRefund
        @refund { amount, description }, (err) ->
          return callback err  if err
        
          callback null, amount
      else
        callback null, 0


  resume: (callback) ->
    @invokeMethod 'reactivateSubscription', callback

  checkUsage: (product, multiplyFactor, callback) ->
    JPaymentPlan = require './plan'

    [callback, multiplyFactor] = [multiplyFactor, callback]  unless callback

    multiplyFactor ?= 1

    { quantities } = product

    unless quantities?
      quantities = {}
      quantities[product.planCode] = 1

    JPaymentPlan.fetchPlanByCode @planCode, (err, plan) =>
      return callback err  if err
      return callback { message: 'unknown plan code', @planCode }  unless plan

      plan.checkQuota @usage, quantities, multiplyFactor, callback

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

  debit: (pack, multiplyFactor, callback) ->
    [callback, multiplyFactor] = [multiplyFactor, callback]  unless callback
    multiplyFactor ?= 1

    @checkUsage pack, multiplyFactor, (err, usage) =>
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

  debit$: secure (client, pack, multiplyFactor, callback) ->
    JPaymentPlan = require './plan'

    { delegate } = client.connection

    @isOwnedBy delegate, (err, hasTarget) =>
      return callback err  if err
      return callback { message: 'Access denied!' }  unless hasTarget

      @debit pack, callback, multiplyFactor

  credit: (pack, callback) ->
    @debit pack, -1, callback

  credit$: secure (client, pack, callback) ->
    @debit$ client, pack, -1, callback

  upgrade: (account, oldPlan, newPlan, callback) ->
    newPlan.checkQuota @usage, {}, (err) =>
      return callback { message: 'Quota succeeded!' }  if err

      @terminate oldPlan, (err, refundAmount) =>
        return callback err  if err

        newPlan.subscribe @paymentMethodId, (err, newSubscription) =>
          return callback err  if err

          account.addSubscription newSubscription, (err) =>
            return callback err  if err
            
            newSubscription.update $set: usage: @usage, (err) ->
              return callback err  if err

              callback null, newSubscription

  downgrade: (account, oldPlan, newPlan, callback) ->
    callback null, downgrade: to: newPlan, from: oldPlan

  transitionTo: secure (client, { planCode, paymentMethodId }, callback) ->
    JPaymentPlan = require './plan'
    JPaymentMethod = require './method'

    { delegate } = client.connection

    delegate.fetchPaymentMethods {},
      targetOptions: selector: { paymentMethodId }
    , (err, paymentMethods) =>
      return callback err  if err
      unless paymentMethods?.length is 1
        return callback { message: 'Unrecognized payment method!' }

      @isOwnedBy delegate, (err, hasTarget) =>
        return callback err  if err
        return callback { message: 'Access denied!' }  unless hasTarget

        oldPlan = null
        newPlan = null

        queue = [
          => JPaymentPlan.fetchPlanByCode @planCode, (err, plan_) ->
            oldPlan = plan_
            queue.fin err

          -> JPaymentPlan.fetchPlanByCode planCode, (err, plan_) ->
            newPlan = plan_
            queue.fin err
        ]
        dash queue, =>
          if oldPlan.feeAmount > newPlan.feeAmount
            @downgrade delegate, oldPlan, newPlan, callback
          else
            @upgrade delegate, oldPlan, newPlan, callback
