Broker = require 'broker'
mongo = require 'mongoskin'

module.exports = 

  distributeActivityToFollowers: (options = {}) ->
    options.host ?= "localhost"
    options.login ?= "guest"
    options.password ?= "guest"
    mq = new Broker options

    exchangePrefix = options.exchangePrefix ? "x"

    dbUrl = options.mongo ? "mongodb://dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect"
    db = mongo.db dbUrl
    feedsCol = db.collection 'jFeeds'
    relationshipsCol = db.collection 'relationships'
    mq.subscribe "koding-feeder", {exclusive: false}, (message, headers, deliveryInfo) =>
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
    options.host ?= "localhost"
    options.login ?= "guest"
    options.password ?= "guest"
    mq = new Broker options
    JAccount = require './models/account'


    # For every account, declare its exchange

    mq.

    # Remove all exchange bindings

    # Find all followers

    # Establish exchange to exchange for each follower



    # dbUrl = options.mongo ? "mongodb://dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect"
    # db = mongo.db dbUrl

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


