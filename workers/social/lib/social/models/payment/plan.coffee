JPaymentBase = require './base'

module.exports = class JPaymentPlan extends JPaymentBase

  force =
    forceRefresh  : yes
    forceInterval : 60

  recurly = require 'koding-payment'
  createId = require 'hat'

  {secure, dash}        = require 'bongo'
  {difference, extend}  = require 'underscore'

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
        'fetchProducts'
        'updateProducts'
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
      feeUnit       : (require './schema').feeUnit
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
      quantities    :
        type        : Object
        default     : -> {}
      tags          : (require './schema').tags
      sortWeight    : Number
    relationships   :
      product       :
        targetType  : 'JPaymentProduct'
        as          : 'plan product'

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

  @fetchAccountDetails = secure ({connection:{delegate}}, callback) ->
    console.error 'needs to be reimplemented'
#    recurly.fetchAccountDetailsByPaymentMethodId (JPayment.userCodeOf delegate), callback

  @fetchPlans = secure (client, options, callback) ->
    # TODO: this method seems redundant/confusing/unnecessary C.T.
    options = tag: options  if 'string' is typeof options
    options.limit = Math.min options.limit ? 20, 20
    
    options.sort ?= sortWeight: 1

    selector =
      tags  : options.tag
      group : client.context.group

    queryOptions =
      limit : options.limit
      sort  : options.sort

    @some selector, queryOptions, callback

  @fetchPlanByCode = (planCode, callback) -> @one { planCode }, callback

  fetchToken: secure (client, data, callback) ->
    JPaymentToken.createToken client, planCode: @planCode, callback

  subscribe: (paymentMethodId, options, callback) ->
    [callback, options] = [options, callback]  unless callback

    options ?= {}
    options.multiple ?= no

    JPaymentSubscription.fetchAllSubscriptions {
      paymentMethodId
      @planCode
      $or       : [
        {status : 'active'}
        {status : 'canceled'}
      ]
    }, (err, [sub]) =>
      return callback err  if err

      if sub?
        return callback 'Already subscribed.'  unless options.multiple

        quantity = sub.quantity + 1

        update = {
          @planCode
          quantity
          uuid: sub.uuid
        }

        recurly.updateSubscription paymentMethodId, update, (err) =>
          return callback err  if err
          sub.update $set: { quantity }, (err)->
            if err
            then callback err
            else callback null, sub

      else
        recurly.createSubscription paymentMethodId, { @planCode }, (err, result) =>
          return callback err  if err

          { planCode, uuid, quantity, status, activatedAt, expiresAt, renewAt,
            feeAmount } = result

          sub = new JPaymentSubscription {
            planCode
            uuid
            quantity
            status
            activatedAt
            expiresAt
            renewAt
            feeAmount
            tags      : @tags
          }

          sub.save (err)->
            return callback err  if err

            callback null, sub

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
