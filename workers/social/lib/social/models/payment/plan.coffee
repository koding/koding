jraphical = require 'jraphical'
recurly   = require 'koding-payment'

forceRefresh  = yes
forceInterval = 60

module.exports = class JPaymentPlan extends jraphical.Module

  {secure, dash}       = require 'bongo'
  {difference, extend} = require 'underscore'

  JUser                = require '../user'
  JPayment             = require './index'
  JPaymentToken        = require './token'
  JPaymentSubscription = require './subscription'

  @share()

  @set
    indexes:
      code         : 'unique'
    sharedMethods  :
      static       : ['fetchPlans', 'getPlanWithCode', 'fetchAccountDetails']
      instance     : ['getToken', 'getType', 'subscribe', 'getSubscriptions']
    schema         :
      code         : String
      title        : String
      description  : Object
      feeMonthly   : Number
      feeInitial   : Number
      feeInterval  : Number
      product      :
        prefix     : String
        category   : String
        item       : String
        version    : Number
      lastUpdate   : Number

  @fetchAccountDetails = secure ({connection:{delegate}}, callback)->
    recurly.fetchAccountDetailsByAccountCode (JPayment.userCodeOf delegate), callback

  @fetchPlans = secure (client, filter..., callback)->
    [prefix, category, item] = filter
    selector = {}
    selector['product.prefix']   = prefix    if prefix
    selector['product.category'] = category  if category
    selector['product.item']     = item      if item

    JPayment.invalidateCacheAndLoad this, selector, {forceRefresh, forceInterval}, callback

  @getPlanWithCode = (code, callback)->
    JPaymentPlan.one { code }, callback

  getToken: secure (client, data, callback)->
    JPaymentToken.createToken client, planCode: @code, callback

  doSubscribe = (code, data, callback)->
    data.multiple ?= no

    JPaymentSubscription.getAllSubscriptions {
      userCode
      planCode  : @code
      $or       : [
        {status : 'active'}
        {status : 'canceled'}
      ]
    }, (err, [sub])=>
      return callback err  if err

      if sub
        return callback 'Already subscribed.'  unless data.multiple

        sub.quantity ?= 1
        recurly.updateSubscription userCode,
          quantity : ++subs.quantity
          plan     : @code
          uuid     : subs.uuid
        , (err)=>
          return callback err  if err
          sub.save (err)-> callback err, sub
      else
        recurly.createSubscription userCode, plan: @code, (err, result)->
          return callback err  if err
          {planCode: plan, uuid, quantity, status, datetime, expires, renew, amount} = result
          sub = new JPaymentSubscription {
            userCode, planCode, uuid, quantity, status, datetime, expires, renew, amount
          }
          sub.save (err)-> callback err, sub

  subscribe: secure ({connection:{delegate}}, data, callback)->
    doSubscribe "user_#{delegate._id}", data, callback

  subscribeGroup: (group, data, callback)->
    doSubscribe "group_#{group._id}", data, callback

  getSubscription: secure ({connection:{delegate}}, callback)->
    JPaymentSubscription.one {userCode: "user_#{delegate._id}", planCode: @code}, callback

  getType:-> if @feeInterval is 1 then 'recurring' else 'single'

  getSubscriptions: (callback)->
    JPaymentSubscription.all
      planCode: @code
      $or: [
        { status: 'active' }
        { status: 'canceled' }
      ]
    , callback

  getOwnerGroup: (callback)->
    if @product.prefix isnt 'groupplan'
      callback null, 'koding'
    else
      JGroup = require '../group'
      JGroup.one _id: @product.category, (err, group)->
        callback err, unless err then group.slug

  @updateCache = (selector, callback)->
    # TODO: what on earth is the point of this? C
    JPayment.updateCache(
      constructor   : this
      method        : 'fetchPlans'
      keyField      : 'code'
      message       : 'product cache'
      forEach       : (k, cached, plan, stackCb)->
        return stackCb()  unless k.match /^([a-zA-Z0-9-]+_){3}[0-9]+$/

        {title, desc, feeMonthly, feeInitial, feeInterval} = plan

        [prefix, category, item, version] = k.split '_'

        version++

        description = (try JSON.parse desc)

        cached.set {
          title
          description
          feeMonthly
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

        cached.save stackCb

    , callback)
