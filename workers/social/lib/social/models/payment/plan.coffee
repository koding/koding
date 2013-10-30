jraphical = require 'jraphical'
module.exports = class JPaymentPlan extends jraphical.Module

  force =
    forceRefresh  : yes
    forceInterval : 60

  recurly = require 'koding-payment'
  createId = require 'hat'

  {secure, dash}       = require 'bongo'
  {difference, extend} = require 'underscore'

  {permit}             = require '../group/permissionset'

  JUser                = require '../user'
  JPayment             = require './index'
  JPaymentToken        = require './token'
  JPaymentSubscription = require './subscription'

  @share()

  @set
    indexes         :
      planCode      : 'unique'
    sharedMethods   :
      static        : [
        'create'
        'removeByCode'
        'fetchPlans'
        'fetchPlanByCode'
        'fetchAccountDetails'
      ]
      instance      : [
        'fetchToken'
        'subscribe'
        'modify'
      ]
    schema          :
      planCode      :
        type        : String
        required    : yes
      title         :
        type        : String
        required    : yes
      description   : Object # TODO: see below*
      feeAmount     :
        type        : Number
        validate    : (require './validators').fee
      feeInitial    :
        type        : Number
        validate    : (require './validators').fee
      feeInterval   :
        type        : Number
        default     : 1
      product       :
        prefix      : String
        category    : String
        item        : String
        version     : Number
      lastUpdate    : Number
      contents      : Object
      group         :
        type        : String
        required    : yes

  # * It seems like we're stuffing some JSON into the description field
  #   on recurly.  I think that's a really bad idea, so let's store any
  #   data that is orthogonal to the recurly API in our own database,
  #   the way we're doing with JPaymentProduct C.T.

  @create = (group, formData, callback) ->

    JGroup = require '../group'

    { title, description, feeAmount } = formData

    plan = new this {
      planCode    : createId()
      title
      description
      feeAmount
      feeInitial  : 0
      feeInterval : 1
      group
    }

    plan.save (err) ->
      return callback err  if err

      recurly.createPlan plan, (err) ->
        return callback err  if err

        JGroup.one slug: group, (err, group) ->
          return callback err  if err

          group.addPlan plan, (err) ->
            return callback err  if err

            callback null, plan

  @create$ = permit 'manage products',
    success: (client, formData, callback) ->
      @create client.context.group, formData, callback

  @removeByCode = (planCode, callback) ->
    @one { planCode }, (err, plan) ->
      return callback err  if err

      unless plan?
        return callback { message: 'Unrecognized plan code', planCode }

      plan.remove callback

  @removeByCode$ = permit 'manage products',
    success: (client, planCode, callback) -> @removeByCode planCode, callback

  @fetchAccountDetails = secure ({connection:{delegate}}, callback) ->
    console.error 'needs to be reimplemented'
#    recurly.fetchAccountDetailsByPaymentMethodId (JPayment.userCodeOf delegate), callback

  @fetchPlans = secure (client, options, callback) ->
    console.log 'FETCH PLANS'

    selector = (Object.keys options)
      .reduce( (acc, key) ->
        acc["product.#{key}"] = options[key]
        acc
      , {})

    JPayment.invalidateCacheAndLoad this, selector, force, callback

  @fetchPlanByCode = (planCode, callback) -> @one { planCode }, callback

  remove: (callback) ->
    { planCode } = this
    super (err) ->
      if err
        callback err
      else if planCode?
        recurly.deletePlan { planCode }, callback
      else
        callback null

  remove$: permit 'manage products',
    success: (client, callback) -> @remove callback

  modify: (formData, callback) ->
    @update $set: formData, callback

  modify$: permit 'manage products',
    success: (client, formData, callback) -> @modify formData, callback

  fetchToken: secure (client, data, callback) ->
    JPaymentToken.createToken client, planCode: @planCode, callback

  subscribe: (paymentMethodId, data, callback) ->
    data.multiple ?= no

    JPaymentSubscription.fetchAllSubscriptions {
      paymentMethodId
      planCode  : @planCode
      $or       : [
        {status : 'active'}
        {status : 'canceled'}
      ]
    }, (err, [sub]) =>
      return callback err  if err

      if sub
        return callback 'Already subscribed.'  unless data.multiple

        quantity = (sub.quantity ? 1) + 1

        recurly.updateSubscription paymentMethodId,
          quantity : quantity
          plan     : @planCode
          uuid     : sub.uuid
        , (err) =>
          return callback err  if err
          sub.update $set: { quantity }, (err)->
            if err
            then callback err
            else callback null, sub
      else
        recurly.createSubscription paymentMethodId, plan: @planCode, (err, result) ->
          return callback err  if err
          console.log { err, result }
          { planCode, uuid, quantity, status, activatedAt, expiresAt, renewAt,
            amount } = result
          sub = new JPaymentSubscription {
            planCode, uuid, quantity, status, activatedAt, expiresAt, renewAt, amount
          }
          console.log sub
          sub.save (err)->
            console.log { err, sub }
            callback err, sub

  subscribe$: secure ({connection:{delegate}}, paymentMethodId, data, callback) ->
    @subscribe paymentMethodId, data, callback

  # subscribeGroup: (group, data, callback)->
  #   doSubscribe "group_#{group._id}", data, callback

  fetchSubscription: secure ({ connection:{ delegate }}, callback) ->
    selector    =
      userCode  : "user_#{delegate.getId()}"
      planCode  : @planCode

    JPaymentSubscription.one selector, callback

  getType:-> if @feeInterval is 1 then 'recurring' else 'single'

  fetchSubscriptions: (callback) ->
    JPaymentSubscription.all
      planCode: @planCode
      $or: [
        { status: 'active' }
        { status: 'canceled' }
      ]
    , callback

  fetchOwnerGroup: (callback) ->
    if @product.prefix isnt 'groupplan'
      callback null, 'koding'
    else
      JGroup = require '../group'
      JGroup.one _id: @product.category, (err, group)->
        callback err, unless err then group.slug

  @updateCache = (selector, callback)->
    # TODO: what on earth is the point of this? C
    JPayment.updateCache(
      constructor : this
      method      : 'fetchPlans'
      keyField    : 'planCode'
      message     : 'product cache'
      forEach     : (k, cached, plan, fin)->
        return fin()  unless k.match /^([a-zA-Z0-9-]+_){3}[0-9]+$/

        {title, desc, feeAmount, feeInitial, feeInterval} = plan

        [prefix, category, item, version] = k.split '_'

        version++

        description = (try JSON.parse desc)

        cached.set {
          title
          description
          feeAmount
          feeInitial
          feeInterval
          lastUpdate: Date.now()
          product: {
            prefix
            category
            item
            version
          }
        }

        cached.save fin

    , callback)
