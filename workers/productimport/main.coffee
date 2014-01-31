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
          JPaymentProduct.one title : pack.title, (err, product) ->
            return console.error "product cannot be added to pack" if err or not product
            quantities = {}
            quantities[product.planCode] = 1
            pack.updateProducts quantities, (err) ->
              return console.error err if err
              console.log "#{pack.title} pack products are added"
              fin()
          
  , -> callback null

  insertPacks pack for pack in data

importPlans = (callback) ->
  data = require(__dirname + '/plans');
  {JPaymentPlan, JPaymentProduct} = worker.models

  productPlanCodes = {}
  JPaymentProduct.all title : $in : ["User", "Group", "VM"], (err, products) ->
    return console.error "products cannot be fetched" if err
    for product in products
      productPlanCodes[product.title] = product.planCode

    console.log 'Codes', productPlanCodes
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
              quantities[productPlanCodes["VM"]] = 1
              quantities[productPlanCodes["Group"]] = 1
              quantities[productPlanCodes["User"]] = 1
            else
              quantities[productPlanCodes["VM"]] = plan.count
            
            console.log 'quantities', quantities
            newPlan.updateProducts quantities, (err) ->
              return console.error err if err
              console.log "#{plan.title} plan products are added"
              fin()
    , -> callback null

    insertPlans plan for plan in data

createBot = (callback) ->
  {JUser} = worker.models

  userInfo = 
    username  : "Bot"
    email     : "bot@koding.com"
    firstName : "Bot"
    lastName  : " "

  JUser.createUser userInfo, (err) ->
    return console.log err if err
    JUser.one username : "bot", (err, user) ->
      user.confirmEmail (err) ->
        return console.error err if err
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

 