Broker = require 'broker'
mongoskin = require 'mongoskin'

module.exports = 

  distributeActivityToFollowers: (options = {}) ->
    {mq, mongo, exchangePrefix} = options
    mq ?= 
      host: "localhost"
      login: "guest"
      password: "guest"
      vhost: "/"
    broker = new Broker mq

    exchangePrefix = exchangePrefix ? "x"

    dbUrl = mongo ? "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"
    db = mongoskin.db dbUrl
    feedsCol = db.collection 'jFeeds'
    relationshipsCol = db.collection 'relationships'
    broker.subscribe "koding-feeder", {exclusive: false}, (message, headers, deliveryInfo) =>
      # The message will come from feed's owner's exchange with the routing
      # key of format "activityOf.#{followee}", payload is the activity.
      {exchange, routingKey, _consumerTag} = deliveryInfo
      activity = JSON.parse message

      regEx = new RegExp "^#{exchangePrefix}"
      owner = exchange.replace regEx, ""

      feedCriteria = {owner: owner, title: "followed"}
      feedsCol.findOne feedCriteria, {'_id':1}, (err, feed) =>
        unless err
          criteria =
            targetName  : "CActivity"
            targetId    : activity._id
            sourceName  : "JFeed"
            sourceId    : feed._id
            as          : "container"

          relationshipsCol.update criteria, criteria, {upsert:true}

  ensureExchangeMesh: (options) ->

  ###
  function ensureuserFeeds (Array feeds) -> void()
  feeds = [feed]
  feed = {title, description}
  ###
  ensureUserFeeds: (feeds) ->
    JAccount  = require './models/account'
    JFeed     = require './models/feed'

    JAccount.someData {}, {}, (err, cursor) ->
      if err
        console.log "Error finding users"
      else
        cursor.each (err, doc) ->
          account = new JAccount doc
          for feedInfo in feeds
            JFeed.assureFeed account, feedInfo, (err, feed) ->


