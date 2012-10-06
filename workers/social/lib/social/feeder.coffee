Broker = require 'broker'
mongoskin = require 'mongoskin'
{ObjectId} = require 'bongo'

module.exports = 
  distributeActivityToFollowers: (options = {}) ->
    {mq, mongo, exchangePrefix} = options
    mq ?= 
      host: "localhost"
      login: "guest"
      password: "guest"
      vhost: "/"
    broker = new Broker mq

    exchangePrefix = exchangePrefix ? "followable-"

    dbUrl = mongo ? "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"
    db = mongoskin.db dbUrl
    feedsCol = db.collection 'jFeeds'
    relationshipsCol = db.collection 'relationships'
    accountsCol = db.collection 'jAccounts'

    broker.subscribe "koding-feeder", {exclusive: false}, (message, headers, deliveryInfo) =>
      
      {exchange, routingKey, _consumerTag} = deliveryInfo
      activity = JSON.parse message
      regEx = new RegExp "^#{exchangePrefix}"
      owner = ObjectId(exchange.replace regEx, "")
      
      selector = sourceId: owner, as: "follower"
      # Get the follower's id
      cursor = relationshipsCol.find selector, {targetId: true}
      cursor.each (err, rel) ->
        if err or not rel
          #console.log "Failed to find follower", err
        else
          selector = {owner: rel.targetId, title: "followed"}
          # Get the follower's feed
          feedsCol.findOne selector, _id:true, (err, feed) ->

            if err or not feed
              #console.log err
            else
              criteria =
                targetName  : "CActivity"
                targetId    : activity._id
                sourceName  : "JFeed"
                sourceId    : feed._id
                as          : "container"

              relationshipsCol.update criteria, criteria, {upsert:true}


  assureExchangeMesh: (options) ->

  ###
  function ensureuserFeeds (Array feeds) -> void()
  feeds = [feed]
  feed = {title, description}
  ###
  assureUserFeeds: (feeds) ->
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


