Bongo   = require 'bongo'
Broker  = require 'broker'
{argv}  = require 'optimist'

{daisy, race} = Bongo

{mongo, mq} = require('koding-config-manager').load("main.#{argv.c}")

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
  data = require(__dirname + '/products');

  queue = []
  insertProducts = race (i, product, fin) ->
    {title} = product  
    {JPaymentProduct} = worker.models
    JPaymentProduct.one title: title, (err, paymentProduct) ->
      return console.error err if err
      if paymentProduct? 
        console.log "#{product.title} product is already added" 
        fin()
      else
        JPaymentProduct.create "koding", product, (err) ->
          console.log "#{product.title} product added successfully" unless err
          fin()
  , -> callback null

  insertProducts product for product in data

importPacks = (callback) ->
  data = require(__dirname + '/packs');

  queue = []
  fetchAllProducts (err, productPlanCodes) ->
    return console.error err if err
    insertPacks = race (i, pack, fin) ->
      {title} = pack  
      {JPaymentPack, JPaymentProduct} = worker.models
      JPaymentPack.one title: title, (err, paymentPack) ->
        return console.error err if err
        if paymentPack? 
          console.log "#{pack.title} pack is already added" 
          fin()
        else
          JPaymentPack.create "koding", pack, (err, pack) ->
            return console.error err if err
            console.log "#{pack.title} pack added successfully" 

            quantities = {}
            if pack.title is "VM"
              quantities[productPlanCodes["CPU"]] = 1
              quantities[productPlanCodes["RAM"]] = 1
              quantities[productPlanCodes["VM"]] = 1
            else
              quantities[productPlanCodes[pack.title]] = 1
            pack.updateProducts quantities, (err) ->
              return console.error err if err
              console.log "#{pack.title} pack products are added"
              fin()
            
    , -> callback null

    insertPacks pack for pack in data

fetchAllProducts = (callback) ->
  {JPaymentProduct} = worker.models
  productPlanCodes = {}
  JPaymentProduct.all {}, (err, products) ->
    return console.error "products cannot be fetched" if err
    for product in products
      productPlanCodes[product.title] = product.planCode

    callback null, productPlanCodes

importPlans = (callback) ->
  data = require(__dirname + '/plans');
  {JPaymentPlan} = worker.models

  fetchAllProducts (err, productPlanCodes) ->
    return console.error err if err
    queue = []
    insertPlans = race (i, plan, fin) ->
      {title} = plan  
      JPaymentPlan.one title: title, (err, paymentPlan) ->
        return console.error err if err
        if paymentPlan? 
          console.log "#{plan.title} plan is already added" 
          fin()
        else
          JPaymentPlan.create "koding", plan, (err, newPlan) ->
            return console.error err if err
            console.log "#{plan.title} plan added successfully" 
            quantities = {}
            if plan.title is "Custom Plan" 
              quantities[productPlanCodes["CPU"]] = 1
              quantities[productPlanCodes["RAM"]] = 1
              quantities[productPlanCodes["Disk"]] = 1
              quantities[productPlanCodes["Always On"]] = 1
              quantities[productPlanCodes["VM"]] = 5
              quantities[productPlanCodes["User"]] = 1
              quantities[productPlanCodes["Group"]] = 1
            else
              {count} = plan
              quantities[productPlanCodes["CPU"]] = count
              quantities[productPlanCodes["RAM"]] = count
              quantities[productPlanCodes["Disk"]] = count
              quantities[productPlanCodes["Always On"]] = count
              quantities[productPlanCodes["VM"]] = count * 5
            
            console.log 'quantities', quantities
            newPlan.updateProducts quantities, (err) ->
              return console.error err if err
              console.log "#{plan.title} plan products are added"
              fin()
    , -> callback null

    insertPlans plan for plan in data

createBot = (callback) ->
  {JUser, JAccount} = worker.models

  userInfo = 
    username  : "bot"
    email     : "bot@koding.com"
    firstName : "Bot"
    lastName  : " "

  JUser.createUser userInfo, (err) ->
    return console.log err if err
    JUser.one username : "bot", (err, user) ->
      user.confirmEmail (err) ->
        return console.error err if err
        JAccount.update "profile.nickname" : "bot", {$set: type: "registered"}, \
          {multi: no}, (err, account) ->
            return callback err if err
            console.log "bot created"
            callback null


initProducts = ->
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
      -> createBot ->
        queue.next()
      -> process.exit(1)
    ]

    daisy queue
    

initProducts()

 