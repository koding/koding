Bongo     = require 'bongo'
Broker    = require 'broker'
{ argv }  = require 'optimist'

{ daisy, race } = Bongo

{ mongo, mq } = require('koding-config-manager').load("main.#{argv.c}")

if 'string' is typeof mongo
  mongo = "mongodb://#{mongo}?auto_reconnect"

broker = new Broker mq

worker = new Bongo {
  mongo  : mongo
  mq     : broker
  root   : __dirname
  models : '../social/lib/social/models'
}

importProducts = (callback) ->
  data = require(__dirname + '/products')
  queue = []
  insertProducts = race (i, product, fin) ->
    { JPaymentProduct } = worker.models
    kreate = ->
      JPaymentProduct.create 'koding', product, (err) ->
        console.log "#{product.title} product added successfully" unless err
        fin()

    { title } = product
    JPaymentProduct.one { title: title }, (err, paymentProduct) ->
      if err
        console.error err
        return fin()

      return kreate()  unless paymentProduct

      console.error "#{product.title} already exists"
      fin()
  , -> callback null

  insertProducts product for product in data

importPacks = (callback) ->
  data = require(__dirname + '/packs')
  queue = []
  fetchAllProducts (err, productPlanCodes) ->
    if err
      console.error err
      return callback err
    insertPacks = race (i, pack, fin) ->
      { title } = pack
      { JPaymentPack, JPaymentProduct } = worker.models

      kreate = ->
        JPaymentPack.create 'koding', pack, (err, pack) ->
          if err
            console.error err
            fin()

          console.log "#{pack.title} pack added successfully"

          quantities = {}
          quantities[productPlanCodes[pack.title]] = 1
          pack.updateProducts quantities, (err) ->
            return console.error err  if err
            console.log "#{pack.title} pack products are added"
            fin()

      JPaymentPack.one { title: title }, (err, paymentPack) ->
        if err
          console.error err  if err
          fin()
        return kreate()  unless paymentPack
        console.error "#{pack.title} already exists"
        fin()
    , -> callback null

    insertPacks pack for pack in data

fetchAllProducts = (callback) ->
  { JPaymentProduct } = worker.models
  productPlanCodes = {}
  JPaymentProduct.all {}, (err, products) ->
    return console.error 'products cannot be fetched' if err
    for product in products
      productPlanCodes[product.title] = product.planCode

    callback null, productPlanCodes

importPlans = (callback) ->
  data = require(__dirname + '/plans')
  { JPaymentPlan } = worker.models

  fetchAllProducts (err, productPlanCodes) ->
    return console.error err  if err

    queue = []
    insertPlans = race (i, plan, fin) ->
      kreate = ->
        JPaymentPlan.create 'koding', plan, (err, newPlan) ->
          if err
            console.error err
            fin()

          console.log "#{plan.title} plan added successfully"
          quantities = {}
          switch plan.title
            when 'Team Plan'
              quantities[productPlanCodes['Always On']] = 1
              quantities[productPlanCodes['VM']] = 2
              quantities[productPlanCodes['User']] = 1
              quantities[productPlanCodes['Group']] = 1
            when 'Free plan'
              quantities[productPlanCodes['VM']] = 1
            else
              { count } = plan
              quantities[productPlanCodes['Always On']] = count
              quantities[productPlanCodes['VM']] = count * 2

          console.log 'quantities', quantities
          newPlan.updateProducts quantities, (err) ->
            if err then console.error err
            else console.log "#{plan.title} plan products are added"
            fin()

      { title } = plan
      JPaymentPlan.one { title: title }, (err, paymentPlan) ->
        if err
          console.error err
          fin()
        return kreate() unless paymentPlan

        console.error "#{plan.title} already exists"
        fin()

    , -> callback null

    insertPlans plan for plan in data

createBot = (callback) ->
  { JUser, JAccount } = worker.models

  userInfo =
    username  : 'bot'
    email     : 'bot@koding.com'
    firstName : 'Bot'
    lastName  : ' '

  JUser.createUser userInfo, (err) ->
    return callback err if err
    JUser.one { username : 'bot' }, (err, user) ->
      user.confirmEmail (err) ->
        return callback err if err
        JAccount.update { 'profile.nickname' : 'bot' }, { $set: { type: 'registered' } }, \
          { multi: no }, (err, account) ->
          return callback err if err
          callback null

initFreeSubscriptions = (callback = -> ) ->
  worker.on 'dbClientReady', ->
    { JPaymentSubscription, JAccount, Relationship } = worker.models

    count = 0
    index = 0
    queue = []
    batchHandler = (skip) ->
      JAccount.some { 'type': 'registered' }, { limit: 100, skip }, (err, accounts) ->
        return callback err  if err

        count += accounts.length
        unless accounts.length
          console.log "found #{count} registered accounts and added free plan for #{index} accounts"
          queue.next()
          return callback null

        queue = accounts.map (account) -> ->
          options = { targetOptions: { selector: { tags: 'nosync' } } }
          account.fetchSubscription null, options, (err, subscription) ->
            console.warn "error occurred for #{account?.profile?.nickname}: #{err}"  if err
            return queue.next()  if subscription

            JPaymentSubscription.createFreeSubscription account, (err) ->
              console.log "#{++index}"
              console.warn "error occurred for #{account?.profile?.nickname}: #{err}"  if err
              queue.next()

        queue.push ->
          console.log 'next'
          batchHandler skip + 100

        daisy queue

    batchHandler 0

initPaymentData = ->
  worker.on 'dbClientReady', ->
    queue = [
      -> importProducts ->
        console.log 'Payment products are imported'
        queue.next()
      -> importPlans ->
        console.log 'All payment plans are added'
        queue.next()
      -> importPacks ->
        console.log 'All Packs are added'
        queue.next()
      -> createBot (err) ->
        console.error err  if err
        queue.next()
      -> process.exit(1)
    ]

    daisy queue

switch argv.i
  when 'payment'
    initPaymentData()
  when 'subscription'
    initFreeSubscriptions (err) ->
      process.exit(1)
  else
    console.error 'unknown -i value'


