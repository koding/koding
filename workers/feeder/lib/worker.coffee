mongoskin = require 'mongoskin'
Broker = require 'broker'
{ObjectId} = require 'bongo'

Object.defineProperty global, 'KONFIG', value: require './config'
{mq, mongo, queueName, exchangePrefix} = KONFIG

mq ?= 
  host: "localhost"
  login: "guest"
  password: "guest"
  vhost: "/"

queueName ?= "koding-feeder"
exchangePrefix ?= "followable-"
dbUrl = mongo ? "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"

broker = new Broker mq
db = mongoskin.db dbUrl

feedsCol = db.collection 'jFeeds'
relationshipsCol = db.collection 'relationships'
accountsCol = db.collection 'jAccounts'

queueOpts = {durable: true, exclusive:false, autoDelete:false}
broker.createQueue queueName, queueOpts, (queue) ->
  # Using prefetchCount to tell RabbitMQ not to dispatch a new message
  # to a worker until it has processed and acknowledged the previous one.
  # Instead, it will dispatch it to the next worker that is not still busy.
  queue.subscribe {ack:true, prefetchCount:1}, (message, headers, deliveryInfo) =>
    {exchange, routingKey, _consumerTag} = deliveryInfo
    message = message.data+"" if message.data?

    #console.log "Feed worker receives message #{message} on exchange #{exchange}"
    try
      activityId = ObjectId message
      regEx = new RegExp "^#{exchangePrefix}"
      ownerString = exchange.replace regEx, ""
      owner = ObjectId ownerString
    catch e
      queue.shift() # ack the completion
      return

    # Find all the targets that follow activity's owner
    selector = sourceId: owner, as: "follower"
    # Get the followers
    cursor = relationshipsCol.find selector, {targetId: true}

    cursor.each (err, rel) ->
      if err or typeof rel is undefined
        queue.shift()
      else if rel is null # end of query
        queue.shift()
      else
        selector = {owner: rel.targetId, title: "followed"}
        # Get the follower's feed
        feedsCol.findOne selector, _id:true, (err, feed) ->
          if err or not feed
            #console.log "Failed to find feed"
          else
            criteria =
              targetName  : "CActivity"
              targetId    : activityId
              sourceName  : "JFeed"
              sourceId    : feed._id
              as          : "container"

            updateOpts = {upsert:true, safe:true}
            relationshipsCol.update criteria, criteria, updateOpts, (err, count) ->
              if err or count is 0
                #console.log "There is an error saving activity to feed"
              else
                #console.log "Worker finished writing to feed"
