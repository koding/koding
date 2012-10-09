mongoskin = require 'mongoskin'
Broker = require 'broker'

module.exports = 
  distributeActivityToFollowers: (options = {}) ->
    {ObjectId} = require 'bongo'

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
      activityId = ObjectId message
      regEx = new RegExp "^#{exchangePrefix}"
      ownerString = exchange.replace regEx, ""
      owner = ObjectId ownerString

      selector = sourceId: owner, as: "follower"
      # Get the followers
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
                targetId    : activityId
                sourceName  : "JFeed"
                sourceId    : feed._id
                as          : "container"

              relationshipsCol.update criteria, criteria, {upsert:true}


  assureExchangeMesh: (options) ->
    {mq, mongo, exchangePrefix} = options

    mq ?= 
      host: "localhost"
      login: "guest"
      password: "guest"
      vhost: "/"

    broker = new Broker mq

    getExchangeName = (id) ->
      "#{exchangePrefix}#{id}"

    dbUrl = mongo ? "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"
    db = mongoskin.db dbUrl
    accountsCol = db.collection 'jAccounts'
    relationshipsCol = db.collection 'relationships'

    accountsCol.findEach {}, {_id: yes}, (err, {_id}) ->
      userXData = {name:getExchangeName _id}
      # console.log "-------------"
      # console.log "Account #{_id} is following "

      selector =
        targetId  : _id
        sourceName: {$in: ['JAccount', 'JTag']}
        as        : 'follower'
      relationshipsCol.findEach selector, {sourceId: yes}, (err, rel) ->
        if rel?
          console.log sourceId
          followeeXName = getExchangeName rel.sourceId
          followeeXData = {name: followeeXName}
          routing = "#{followeeXName}.activity"
          console.log "---"
          broker.bindExchange userXData, followeeXData, routing

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


