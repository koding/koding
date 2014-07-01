jraphical   = require 'jraphical'
payment     = require 'koding-payment'
KodingError = require '../../error'

forceRefresh  = yes
forceInterval = 60 * 3

module.exports = class JPaymentSubscription extends jraphical.Module

  {secure, dash, daisy, signature} = require 'bongo'

  {partition} = require 'bongo/lib/util'

  JUser    = require '../user'
  JPayment = require './index'

  @share()

  @set
    indexes         :
      uuid          : 'unique'
    sharedEvents    :
      static        : []
      instance      : []
    sharedMethods   :
      static        :
        fetchUserSubscriptions:
          (signature Function)
        fetchUserSubscriptionsWithPlan:
          (signature Function)
      instance      :
        cancel:
          (signature Function)
        resume:
          (signature Function)
        checkUsage: [
          (signature Object, Function)
          (signature Object, Number, Function)
        ]
        checkQuota  :
          (signature Object, Function)
        debit: [
          (signature Object, Function)
          (signature Object, Number, Function)
        ]
        credit:
          (signature Object, Function)
        transitionTo:
          (signature Object, Function)
    schema          :
      uuid          : String
      planCode      : String
      userCode      : String
      couponCode    : String
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
      quantities    :
        type        : Object
        default     : -> {}
      usage         :
        type        : Object # "usage" is designed to mirror "quantities" from JPaymentPlan
        default     : {}
      paymentMethodId: String
      tags          : (require './schema').tags
      transactionLock:
        type        : Boolean
        default     : no
    relationships   :
      linkedSubscription:
        targetType  : this
        as          : 'linked subscription'

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

  @checkUserSubscription = secure ({connection:{delegate}}, planCode, callback)->
    throw Error 'reimplement this!'

  isOwnedBy: (account, callback) ->
    account.hasTarget this, 'service subscription', callback

  refund: (options, callback) ->
    payment.createRefund @paymentMethodId, options, callback

  getEndDate: -> new Date Math.max +(@renewAt ? 0), +(@expiresAt ? 0)

  calculateRefund: ->
    now     = Date.now()
    begin   = +@activatedAt
    end     = +@getEndDate()
    usage   = (now - begin) / (end - begin)
    ratio   = (100 - (usage * 100)) / 100

    return Math.ceil ratio * @feeAmount # cents

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
        Refund for the remaining days of your current plan: #{ oldPlan.title }
        """

      if applyRefund
        @refund { amount, description }, (err) ->
          return callback err  if err

          callback null, amount
      else
        callback null, 0


  resume: (callback) ->
    @fetchLinkedSubscription (err, subscription) =>
      return callback err  if err

      if subscription
        subscription.cancel (err) =>
          return callback err  if err

          @removeLinkedSubscription subscription, (err) =>
            return callback err  if err

            @invokeMethod 'reactivateSubscription', callback
      else
        @invokeMethod 'reactivateSubscription', callback

  checkUsage: (product, multiplyFactor, callback) ->
    [callback, multiplyFactor] = [multiplyFactor, callback]  unless callback
    multiplyFactor ?= 1
    {quantities} = product

    unless quantities?
      quantities = {}
      quantities[product.planCode] = 1

    spend = quantities
    @checkQuota {@usage, @couponCode, spend, multiplyFactor}, callback

  checkQuota: (options, callback) ->
    {usage, spend, couponCode, multiplyFactor} = options
    multiplyFactor ?= 1
    spend ?= {}

    usages = for own planCode, quantity of spend
      planSize    = @quantities[planCode]
      usageAmount = usage[planCode] ? 0
      spendAmount = (spend[planCode] ? 0) * multiplyFactor

      total = planSize - usageAmount - spendAmount

      { planCode, total }

    [ok, over] = partition usages, ({ total }) -> total >= 0

    if over.length > 0
    then callback { message: 'quota exceeded', ok, over, code: 999 }
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

  debit: ({ pack, multiplyFactor, shouldCreateNonce }, callback) ->
    return callback new KodingError "Your subscription is currently locked"  if @transactionLock

    multiplyFactor    ?= 1
    shouldCreateNonce ?= no

    @update $set: transactionLock: yes, (err) =>
      return callback err  if err

      @checkUsage pack, multiplyFactor, (err, usage) =>
        if err
          callback err  if err
          @update $set: transactionLock: no, (err) ->
            console.warn "Transaction lock reset failed"  if err
          return

        { quantities } = pack

        op = $set: (Object.keys quantities).reduce( (memo, key) =>
            memo["usage.#{ key }"] =
              (@usage[key] ? 0) + quantities[key] * multiplyFactor
            memo
          , {})

        op.$set.transactionLock = no

        @update op, (err) =>
          if err
            callback err  if err
            @update $set: transactionLock: no, (err) ->
              console.warn "Transaction lock reset failed"  if err
            return

          if shouldCreateNonce
            @createFulfillmentNonce pack, (multiplyFactor > 0), callback
          else
            callback null

  debit$: secure (client, options, callback) ->
    { delegate } = client.connection

    @isOwnedBy delegate, (err, hasTarget) =>
      return callback err  if err
      return callback { message: 'Access denied!' }  unless hasTarget

      options.shouldCreateNonce ?= yes

      @debit options, callback

  credit: ({pack}, callback) ->
    @debit { pack, multiplyFactor: -1 }, callback

  credit$: secure (client, options, callback) ->
    options.multiplyFactor or= -1
    @debit$ client, options, callback

  applyTransition: (options, callback) ->

    {
      account
      paymentMethodId
      oldPlan
      newPlan
      subOptions
      operation
    } = options

    paymentMethodId ?= @paymentMethodId

    newSubscription = null

    queue = [
      =>
        newPlan.checkQuota {@usage}, (err) -> queue.next err
      ->
        newPlan.subscribe paymentMethodId, subOptions, (err, newSub) ->
          return callback err  if err
          newSubscription = newSub
          queue.next err
      =>
        if operation
        then operation.call this, (err) -> queue.next err
        else queue.next()
      =>
        @addLinkedSubscription newSubscription, (err) -> queue.next err
      ->
        account.addSubscription newSubscription, (err) -> queue.next err
      =>
        {quantities} = newPlan
        newSubscription.update $set: { @usage, quantities }, (err) -> queue.next err
      ->
        callback null, newSubscription
    ]

    daisy queue

  downgrade: (options, callback) ->

    options.subOptions =
      startsAt: @getEndDate()

    if "nosync" not in @tags
      options.operation = (continuation) =>
        @cancel continuation

    @applyTransition options, callback

  upgrade: (options, callback) ->
    if "nosync" not in @tags
      options.operation = (continuation) =>
        @terminate options.oldPlan, continuation

    @applyTransition options, callback

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
          transitionOptions = {
            paymentMethodId
            account: delegate
            oldPlan
            newPlan
          }

          if oldPlan.feeAmount > newPlan.feeAmount
            @downgrade transitionOptions, callback
          else
            @upgrade transitionOptions, callback

  debitPack: ({tag, multiplyFactor}, callback) ->
    multiplyFactor ?= 1
    JPaymentPack = require './pack'
    JPaymentPack.one tags: $in: [tag], {}, (err, pack) =>
      return callback err  if err
      return callback new KodingError "pack not found"  unless pack
      @debit {pack, multiplyFactor}, callback

  creditPack: ({tag, multiplyFactor}, callback) ->
    multiplyFactor ?= 1
    multiplyFactor *= -1
    @debitPack {tag, multiplyFactor}, callback

  @createFreeSubscription = (account, callback) ->
    JPaymentPlan = require './plan'
    JPaymentPlan.one tags: "nosync", (err, plan) ->
      return \
        if err then callback err
        else if not plan then callback new KodingError "nosync plan not found"

      {planCode, quantities, tags} = plan
      freePlanSubscription = new JPaymentSubscription
        planCode   : planCode
        quantity   : 1
        status     : "active"
        feeAmount  : 0
        quantities : quantities
        tags       : tags

      freePlanSubscription.save (err) ->
        return callback new KodingError "nosync subscription failed: #{err}"  if err
        account.addSubscription freePlanSubscription, (err) ->
          return callback new KodingError "couldn't add subscription to account: #{err}"  if err
          callback null, freePlanSubscription

  @isFreeSubscripton:(planCode, callback)->
    @one {planCode}, (err, subscription)->
      return callback err  if err
      return callback null, yes  unless subscription
      # default free vm for users
      return callback null, yes  if "nosync" in subscription.tags
      # if none of the above, they are not free
      return callback null, no
