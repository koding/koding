jraphical = require 'jraphical'
JUser     = require '../user'
payment   = require 'koding-payment'
createId  = require 'hat'
async     = require 'async'

forceRefresh  = yes
forceInterval = 0

module.exports = class JRecurlyPlan extends jraphical.Module

  {secure} = require 'bongo'

  JRecurlyToken        = require './token'
  JRecurlySubscription = require './subscription'

  @share()

  @set
    indexes:
      code         : 'unique'
    sharedMethods  :
      static       : [
        'getPlans', 'getPlanWithCode',
        'setUserAccount', 'getUserAccount', 'getUserTransactions',
        'getUserBalance', 'getGroupBalance'
      ]
      instance     : [
        'getToken', 'subscribe'
      ]
    schema         :
      code         : String
      title        : String
      desc         : String
      feeMonthly   : Number
      feeInitial   : Number
      product      :
        prefix     : String
        category   : String
        item       : String
        version    : Number
      lastUpdate   : Number

  @setUserAccount = secure (client, data, callback)->
    {delegate}    = client.connection

    data.username  = delegate.profile.nickname 
    data.ipAddress = '0.0.0.0'
    data.firstName = delegate.profile.firstName
    data.lastName  = delegate.profile.lastName

    JUser.fetchUser client, (e, r) ->
      data.email = r.email
      payment.setAccount "user_#{delegate._id}", data, (err, res)->
        return callback err  if err
        payment.setBilling "user_#{delegate._id}", data, callback

  @setGroupAccount = (group, data, callback)->
    JRecurlyPlan.fetchGroupAccount group, (err, groupAccount)=>
      return callback err  if err

      userCode         = "group_#{group._id}"
      data.accountCode = userCode
      data.email       = groupAccount.email
      data.username    = groupAccount.username
      data.firstName   = groupAccount.firstName
      data.lastName    = groupAccount.lastName

      payment.setAccountWithBilling userCode, data, callback

  @getUserAccount = secure (client, callback)->
    {delegate}    = client.connection
    payment.getAccount "user_#{delegate._id}", callback

  @getGroupAccount = (group, callback)->
    payment.getAccount "group_#{group._id}", callback

  @getUserTransactions = secure (client, callback)->
    {delegate}    = client.connection
    payment.getUserTransactions "user_#{delegate._id}", callback

  @getGroupTransactions = (group, callback)->
    payment.getUserTransactions "group_#{group._id}", callback

  @getPlans = secure (client, filter..., callback)->
    [prefix, category, item] = filter
    selector = {}
    selector["product.prefix"] = prefix  if prefix
    selector["product.category"] = category  if category
    selector["product.item"] = item  if item

    unless forceRefresh
      JRecurlyPlan.all selector, callback
    else
      JRecurlyPlan.one {}, (err, plan)=>
        callback err  if err
        unless plan
          @updateCache -> JRecurlyPlan.all selector, callback
        else
          plan.lastUpdate ?= 0
          now = (new Date()).getTime()
          if now - plan.lastUpdate > 1000 * forceInterval
            @updateCache -> JRecurlyPlan.all selector, callback
          else
            JRecurlyPlan.all selector, callback

  @getPlanWithCode = (code, callback)->
    JRecurlyPlan.one
      code: code
    , callback

  # Recurly web hook will use this method to invalidate the cache.
  @updateCache = (callback)->
    console.log "Updating Recurly plans..."

    payment.getPlans (err, allPlans)->
      mapAll = {}
      allPlans.forEach (rPlan)->
        mapAll[rPlan.code] = rPlan
      JRecurlyPlan.all {}, (err, cachedPlans)->
        mapCached = {}
        cachedPlans.forEach (cPlan)->
          mapCached[cPlan.code] = cPlan
        stack = []
        Object.keys(mapCached).forEach (k)->
          if k not in Object.keys(mapAll)
            # delete
            stack.push (cb)->
              mapCached[k].remove ->
                cb()
        Object.keys(mapAll).forEach (k)->
          # create or update
          stack.push (cb)->
            {code, title, desc, feeMonthly, feeInitial} = mapAll[k]
            unless code.match /^([a-zA-Z0-9-]+_){3}[0-9]+$/
              cb()
            else
              if k not in Object.keys(mapCached)
                plan = new JRecurlyPlan
                plan.code = code
              else
                plan = mapCached[k]

              plan.title = title
              plan.desc = desc
              plan.feeMonthly = feeMonthly
              plan.feeInitial = feeInitial

              [prefix, category, item, version] = code.split '_'
              version = +version
              plan.product = {prefix, category, item, version}

              plan.lastUpdate = (new Date()).getTime()

              plan.save ->
                cb null, plan

        async.parallel stack, (err, results)->
          callback()

  getToken: secure (client, data, callback)->
    {delegate} = client.connection
    JRecurlyToken.createToken client,
      planCode: @code
    , callback

  @fetchAccount = secure (client, callback)->
    {delegate} = client.connection
    delegate.fetchUser (err, user)->
      return callback err  if err
      account =
        email     : user.email
        username  : delegate.profile.nickname
        firstName : delegate.profile.firstName
        lastName  : delegate.profile.lastName
      callback no, account

  @fetchGroupAccount = (group, callback)->
    group.fetchOwner (err, owner)->
      return callback err  if err
      owner.fetchUser (err, user)->
        return callback err  if err
        account =
          email     : user.email
          username  : group.slug
          firstName : "Group"
          lastName  : group.title
        callback no, account

  subscribe: secure (client, data, callback)->
    {delegate} = client.connection
    userCode   = "user_#{delegate._id}"

    data.multiple ?= no

    JRecurlySubscription.getSubscriptionsAll userCode,
      userCode: userCode
      planCode: @code
      $or      : [
        {status: 'active'}
        {status: 'canceled'}
      ]
    , (err, subs)=>
      return callback err  if err
      if subs.length > 0

        unless data.multiple
          return callback "Already subscribed."

        subs = subs[0]
        subs.quantity ?= 1
        subs.quantity += 1

        payment.updateUserSubscription userCode,
          quantity: subs.quantity
          plan    : @code
          uuid    : subs.uuid
        , (err, result)=>
          subs.save ->
            callback no, subs
      else
        payment.addUserSubscription userCode, {plan: @code}, (err, result)->
          return callback err  if err
          sub = new JRecurlySubscription
            planCode : result.plan
            userCode : userCode
            uuid     : result.uuid
            quantity : result.quantity
            status   : result.status
            datetime : result.datetime
            expires  : result.expires
            renew    : result.renew
          sub.save ->
            callback no, sub

  getSubscription: secure (client, callback)->
    {delegate} = client.connection
    userCode = "user_#{delegate._id}"

    JRecurlySubscription.one
      userCode : userCode
      planCode : @code
    , callback

  subscribeGroup: (group, data, callback)->
    userCode = "group_#{group._id}"

    data.multiple ?= no

    JRecurlySubscription.getSubscriptionsAll userCode,
      userCode: userCode
      planCode: @code
      $or      : [
        {status: 'active'}
        {status: 'canceled'}
      ]
    , (err, subs)=>
      return callback err  if err
      if subs.length > 0        

        unless data.multiple
          return callback "Already subscribed."

        subs = subs[0]
        subs.quantity ?= 1
        subs.quantity += 1

        payment.updateUserSubscription userCode,
          quantity: subs.quantity
          plan    : @code
          uuid    : subs.uuid
        , (err, result)=>
          subs.save ->
            callback no, subs
      else
        payment.addUserSubscription userCode, data, (err, result)->
          return callback err  if err
          sub = new JRecurlySubscription
            planCode : result.plan
            userCode : userCode
            uuid     : result.uuid
            quantity : result.quantity
            status   : result.status
            datetime : result.datetime
            expires  : result.expires
            renew    : result.renew
          sub.save ->
            callback no, sub

  @getAccountBalance = (account, callback)->
    payment.getUserTransactions account, (err, adjs)->
      spent = 0
      adjs.forEach (adj)->
        spent += parseInt adj.amount, 10

      payment.getUserAdjustments account, (err, adjs)->
        charged = 0
        adjs.forEach (adj)->
          charged += parseInt adj.amount, 10

        callback null, spent-charged
      
  @getUserBalance = secure (client, callback)->
    {delegate} = client.connection
    userCode      = "user_#{delegate._id}"

    @getAccountBalance userCode, callback

  @getGroupBalance = secure (client, group, callback)->
    {delegate} = client.connection
    userCode      = "group_#{group._id}"
    
    @getAccountBalance userCode, callback

do ->
  # Koding Recurly Products

  fs      = require 'fs'
  path    = require 'path'
  Watcher = require "koding-watcher"

  getProducts = (callback)->
    productsFile = path.join __dirname, "../../../../../../products/products.json"
    productsList = JSON.parse(fs.readFileSync(productsFile))
    callback productsList

  loadProducts = ->
    getProducts (products)->
      stack = []
      products.forEach (prod)->
        stack.push (cb)->
          payment.getPlanInfo {code: prod.code}, (err, plan)->
            if not err and plan
              payment.updatePlan 
                code       : prod.code
                title      : prod.title
                feeMonthly : prod.price
              , (err, plan)->
                unless err
                  console.log "Updated product: #{prod.title}"
                cb()
            else
              payment.addPlan
                code       : prod.code
                title      : prod.title
                feeMonthly : prod.price
              , (err, plan)->
                unless err
                  console.log "Created product: #{prod.title}"
                cb()

      async.parallel stack, (err, result)->
        JRecurlyPlan.updateCache ->
          JRecurlyPlan.all {}, ->
            console.log "Updated product cache."


  # Load products
  loadProducts()

  # Update products if necessary
  watchRoot = path.join __dirname, "../../../../../../products/"
  watcher   = new Watcher
    groups        :
      recurly     :
        folders   : [watchRoot]
        onChange  : (change)->
          loadProducts()