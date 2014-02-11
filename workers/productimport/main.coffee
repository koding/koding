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
    {JPaymentProduct} = worker.models
    kreate = ->
      JPaymentProduct.create "koding", product, (err) ->
        console.log "#{product.title} product added successfully" unless err
        fin()

    {title} = product  
    JPaymentProduct.one title: title, (err, paymentProduct) ->
      if err 
        console.error err 
        return fin()

      if paymentProduct? 
        paymentProduct.remove (err) ->
          if err
            console.error "#{product.title} cannot be added" 
            fin()
          else
            kreate()
      else
        kreate()
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

      kreate = ->
        JPaymentPack.create "koding", pack, (err, pack) ->
          if err 
            console.error err 
            return fin()

          console.log "#{pack.title} pack added successfully" 

          quantities = {}
          quantities[productPlanCodes[pack.title]] = 1
          pack.updateProducts quantities, (err) ->
            return console.error err if err
            console.log "#{pack.title} pack products are added"
            fin()

      JPaymentPack.one title: title, (err, paymentPack) ->
        if err 
          console.error err
          fin()

        if paymentPack
          paymentPack.remove (err) ->
            if err 
              console.error err
              console.error "#{pack.title} cannot be added"  
              fin()
            else 
              kreate()
        else
          kreate()
            
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
      kreate = ->
        JPaymentPlan.create "koding", plan, (err, newPlan) ->
          if err 
            console.error err
            return fin()

          console.log "#{plan.title} plan added successfully" 
          quantities = {}
          if plan.title is "Team Plan" 
            quantities[productPlanCodes["CPU"]] = 4
            quantities[productPlanCodes["RAM"]] = 2
            quantities[productPlanCodes["Disk"]] = 50
            quantities[productPlanCodes["Always On"]] = 1
            quantities[productPlanCodes["Max VM"]] = 10
            quantities[productPlanCodes["User"]] = 1
            quantities[productPlanCodes["Group"]] = 1
          else
            {count} = plan
            quantities[productPlanCodes["CPU"]] = count * 4
            quantities[productPlanCodes["RAM"]] = count * 2
            quantities[productPlanCodes["Disk"]] = count * 50
            quantities[productPlanCodes["Always On"]] = count
            quantities[productPlanCodes["Max VM"]] = count * 10
          
          console.log 'quantities', quantities
          newPlan.updateProducts quantities, (err) ->
            if err then console.error err
            else console.log "#{plan.title} plan products are added"
            fin()

      {title} = plan  
      JPaymentPlan.one title: title, (err, paymentPlan) ->
        if err 
          console.error err
          return fin()

        if paymentPlan? 
          paymentPlan.remove (err) ->
            if err
              console.error "#{plan.title} cannot be added" 
              fin()
            else
              kreate()
        else
          kreate()
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
    return callback err if err
    JUser.one username : "bot", (err, user) ->
      user.confirmEmail (err) ->
        return callback err if err
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
      -> createBot (err) ->
        console.error err  if err
        queue.next()
      -> process.exit(1)
    ]

    daisy queue
    
initProducts()

 