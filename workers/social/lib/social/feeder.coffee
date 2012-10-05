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
    accountsCol = db.collection 'jAccounts'

    broker.subscribe "koding-feeder", {exclusive: false}, (message, headers, deliveryInfo) =>
      
      {exchange, routingKey, _consumerTag} = deliveryInfo
      activity = JSON.parse message
      regEx = new RegExp "^#{exchangePrefix}"
      owner = exchange.replace regEx, ""

      # # The message will come from feed's owner's exchange with the routing
      # # key of format "activityOf.#{followee}", payload is the activity.
  
      # feedCriteria = {owner: owner, title: "followed"}
      # feedsCol.findOne feedCriteria, {'_id':1}, (err, feed) =>
      #   if err
      #     console.log err
      #   else
      #     criteria =
      #       targetName  : "CActivity"
      #       targetId    : activity._id
      #       sourceName  : "JFeed"
      #       sourceId    : feed._id
      #       as          : "container"

      #     relationshipsCol.update criteria, criteria, {upsert:true}

      #### ABOVE FAILED ###

      # Message come from publisher
      # JAccount.one 'profile.nickname': owner, (err, account) ->
      #   account.fetchFollowers (err, followers) ->
      #     for follower in followers
      #       feedCriteria = {owner: follower.profile.nickname, title: "followed"}
      #       JFeed.someData feedCriteria, {_id: true}, (err, feed) ->

      # Get the publisher's id
      selector = 'profile.nickname': owner
      accountsCol.findOne selector, _id: true, (err, account) ->
        if err
          console.log "Failed to find the publisher account", err
        else
          selector = sourceId: account._id, as: "follower"
          # Get the follower's id
          cursor = relationshipsCol.find selector, {targetId: true}
          cursor.each (err, rel) ->
            if err or not rel
              #console.log "Failed to find follower", err
            else
              selector = _id: rel.targetId
              # Get the follower's nickname
              accountsCol.findOne selector, {"profile.nickname": true}, (err, follower) ->
                if err
                  console.log "Failed to get follower's nickname", err
                else
                  selector = {owner: follower.profile.nickname, title: "followed"}
                  # Get the follower's feed
                  feedsCol.findOne selector, _id:true, (err, feed) ->
                    if err or not feed
                      console.log err
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


