mongoskin = require 'mongoskin'
Broker = require 'broker'

Object.defineProperty global, 'KONFIG', value: require './config'
{mq, mongo, queueName, exchangePrefix} = KONFIG

console.log "Migrator is starting with config:", KONFIG

mq ?= 
  host: "localhost"
  login: "guest"
  password: "guest"
  vhost: "/"

queueName ?= "koding-feeder"
exchangePrefix ?= "followable-"
dbUrl = mongo ? "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"

broker = new Broker mq

getExchangeName = (id) ->
  "#{exchangePrefix}#{id}"

db = mongoskin.db dbUrl
accountsCol = db.collection 'jAccounts'
relationshipsCol = db.collection 'relationships'

accountsCol.count (err, accountCount) ->
  if err
    console.log "Error counting accounts"
    process.exit()
  else
    accountPending = accountCount
    accountSetup = ->
      accountPending--
      if accountPending is 0
        console.log "Migration completed!"
        broker.connection.end()
        process.exit()

    console.log "Migrating #{accountCount} accounts..."
    accountsCol.findEach {}, {_id: yes}, (err, account) ->
      if err or not account?
        console.log "Error checking account", err if err
        return
        #process.exit()
      else
        {_id} = account
        userXData = {name: getExchangeName _id}

        selector =
          targetId  : _id
          sourceName: {$in: ['JAccount', 'JTag']}
          as        : 'follower'

        relationshipsCol.count selector, (err, relCount) ->
          bindingPending = relCount

          if bindingPending is 0
            return accountSetup()

          boundFinished = ->
            bindingPending--
            if bindingPending is 0
              #console.log "finish for account #{_id}"
              accountSetup()

          relationshipsCol.findEach selector, {sourceId: yes}, (err, rel) ->
            if err or not rel?
              console.log "Error finding relationship", err if err
              return
              #process.exit()
            else
              followeeXName = getExchangeName rel.sourceId
              followeeXData = {name: followeeXName}
              routing = "#{followeeXName}.activity"
              broker.bindExchange userXData, followeeXData, routing
              boundFinished()