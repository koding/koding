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

accountsCol.findEach {}, {_id: yes}, (err, accountRel) ->
  if err or typeof accountRel is undefined
    console.log "Error querying accounts. Check your DB configs and try again!"
    process.exit() # exit the worker
  else if accountRel is null
    console.log "No more account. Finished!"
    process.exit() # exit the worker
  else
    {_id} = accountRel
    userXData = {name: getExchangeName _id}
    console.log "Migrating account", _id

    selector =
      targetId  : _id
      sourceName: {$in: ['JAccount', 'JTag']}
      as        : 'follower'

    # Find all the sources that this account is following
    relationshipsCol.findEach selector, {sourceId: yes}, (err, rel) ->
      if err or typeof rel is undefined
        return # go to next account
      else if rel is null # no more followees for this account
        return # go to next account
      else
        followeeXName = getExchangeName rel.sourceId
        followeeXData = {name: followeeXName}
        routing = "#{followeeXName}.activity"
        broker.bindExchange userXData, followeeXData, routing