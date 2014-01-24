JPaymentBase = require './base'

module.exports = class JPaymentPlan extends JPaymentBase

  force =
    forceRefresh  : yes
    forceInterval : 60

  recurly = require 'koding-payment'
  createId = require 'hat'

  {secure, dash, signature}        = require 'bongo'
  {difference, extend}  = require 'underscore'

  {partition}           = require 'bongo/lib/util'
  {permit}              = require '../group/permissionset'

  JUser                 = require '../user'
  JPayment              = require './index'
  JPaymentToken         = require './token'
  JPaymentSubscription  = require './subscription'

  @share()

  @set
    indexes         :
      planCode      : 'unique'
    sharedMethods   :
      static        :
        create      :
          (signature Object, Function)
        removeByCode:
          (signature String, Function)
        fetchPlanByCode:
          (signature String, Function)
        one         :
          (signature Object, Function)
      instance      :
        fetchToken  :
          (signature Object, Function)
        subscribe   :
          (signature String, Object, Function)
        modify      :
          (signature Object, Function)
        fetchProducts: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        updateProducts:
          (signature Object, Function)
        checkQuota  : [
          (signature Object, Function)
        ]
        fetchCoupon:
          (signature String, Function)

    schema              :
      planCode          :
        type            : String
        required        : yes
      title             :
        type            : String
        required        : yes
      description       : Object # TODO: see below*
      feeAmount         :
        type            : Number
        validate        : (require './validators').fee
        default         : 0
      feeInitial        :
        type            : Number
        validate        : (require './validators').fee
      feeInterval       :
        type            : Number
        default         : 1
      feeUnit           : (require './schema').feeUnit
      priceIsVolatile   :
        type            : Boolean
        default         : no
      discountCode      : String
      vmCode            : String
      product           :
        prefix          : String
        category        : String
        item            : String
        version         : Number
      lastUpdate        : Number
      contents          : Object
      group             :
        type            : String
        required        : yes
      quantities        :
        type            : Object
        default         : -> {}
      tags              : (require './schema').tags
      sortWeight        : Number
    relationships       :
      product           :
        targetType      : 'JPaymentProduct'
        as              : 'plan product'

  # * It seems like we're stuffing some JSON into the description field
  #   on recurly.  I think that's a really bad idea, so let's store any
  #   data that is orthogonal to the recurly API in our own database,
  #   the way we're doing with JPaymentProduct C.T.

  @create = (groupSlug, formData, callback) ->

    JGroup = require '../group'

    { title, description, feeAmount, tags, sortWeight } = formData

    plan = new this {
      planCode    : createId()
      title
      description
      feeAmount
      feeInitial  : 0
      feeInterval : 1
      group       : groupSlug
      tags
      sortWeight
    }

    plan.save (err) ->
      return callback err  if err

      recurly.createPlan plan, (err) ->
        return callback err  if err

        JGroup.one slug: groupSlug, (err, group) ->
          return callback err  if err

          group.addPlan plan, (err) ->
            return callback err  if err

            callback null, plan

  @fetchPlanByCode = (planCode, callback) -> @one { planCode }, callback

  userUnitAmount     =  500 # cents
  resourceUnitAmount = 2000 # cents

  calculateCustomPlanUnitAmount = (userQuantity, resourceQuantity) ->
    (userQuantity * userUnitAmount) + (resourceQuantity * resourceUnitAmount)

  fetchToken: secure (client, data, callback) ->
    JPaymentToken.createToken client, planCode: @planCode, callback

  subscribe: (paymentMethodId, options = {}, callback) ->
    [callback, options] = [options, callback]  unless callback
    options.multiple ?= no
    {planOptions, couponCode} = options
    {userQuantity, resourceQuantity} = planOptions  if planOptions

    couponCode = if couponCode is "discount" then @discountCode else @vmCode

    JPaymentSubscription.one {
      paymentMethodId
      @planCode
      $or       : [
        {status : 'active'}
        {status : 'canceled'}
      ]
    }, (err, subscription) =>
      return callback err  if err

      if subscription?
        unless options.multiple
          return callback {
            message               : 'Already subscribed.'
            short                 : 'existing_subscription'
            existingSubscription  : subscription
          }

        quantity = subscription.quantity + 1

        update = {
          @planCode
          couponCode
          quantity
          uuid: subscription.uuid
        }

        recurly.updateSubscription paymentMethodId, update, (err) =>
          return callback err  if err
          subscription.update $set: { quantity }, (err)->
            if err
            then callback err
            else callback null, subscription

      else
        subOptions = {
          @planCode
          couponCode
          startsAt: options.startsAt
        }

        if "custom-plan" in @tags
          unless userQuantity or resourceQuantity
            return callback "User and resource quantities not specified"

          subOptions.unit_amount_in_cents = calculateCustomPlanUnitAmount userQuantity, resourceQuantity

        recurly.createSubscription paymentMethodId, subOptions, (err, result) =>
          return callback err  if err

          { planCode, uuid, quantity, status, activatedAt, expiresAt, renewAt,
            feeAmount, paymentMethodId } = result

          subscription = new JPaymentSubscription {
            planCode
            couponCode
            uuid
            quantity
            status
            activatedAt
            expiresAt
            renewAt
            feeAmount
            paymentMethodId
            tags      : @tags
          }

          subscription.save (err)->
            return callback err  if err

            callback null, subscription

  subscribe$: secure (client, paymentMethodId, data, callback) ->
    { connection:{ delegate } } = client
    [data, callback] = [callback, data]  unless callback
    @subscribe paymentMethodId, data, (err, subscription) ->
      return callback err  if err

      delegate.addSubscription subscription, (err) ->
        return callback err  if err

        callback null, subscription


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

  vmCouponQuota =
    "1freevm"   : 1
    "2freevms"  : 2

  checkQuota: (options, callback) ->
    {usage, spend, couponCode, multiplyFactor} = options
    multiplyFactor ?= 1

    usages = for own planCode, quantity of spend
      planSize    = @quantities[planCode] ? 0
      usageAmount = usage[planCode] ? 0
      spendAmount = (spend[planCode] ? 0) * multiplyFactor

      planSize += vmCouponQuota[couponCode]  if couponCode of vmCouponQuota
      total = planSize - usageAmount - spendAmount

      { planCode, total }

    [ok, over] = partition usages, ({ total }) -> total >= 0

    if over.length > 0
    then callback { message: 'quota exceeded', ok, over }
    else callback null

  fetchCoupon: (type, callback) ->
    code = if type is "discount" then @discountCode else @vmCode
    recurly.fetchCoupon code, callback
