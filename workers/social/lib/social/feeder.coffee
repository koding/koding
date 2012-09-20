module.exports = class Feeder
  Broker = require 'broker'
  mongo = require 'mongoskin'

  constructor: (options = {}) ->
    options.host ?= "localhost"
    options.login ?= "guest"
    options.password ?= "guest"
    @mq = new Broker options
    db = mongo.db "mongodb://dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect"
    @feeds = db.collection 'jFeeds'
    @relationships = db.collection 'relationships'

    @mq.subscribe "koding-feeder", {exclusive: false}, (message, headers, deliveryInfo) =>
      # The message will come from the person who publish the message,
      # not who receive it. Not sure how to get the owner of the feed.
      {exchange, routingKey, consumerTag} = deliveryInfo
      activity = JSON.parse message

      console.log "Worker receives message from #{exchange} on #{routingKey}"

      # @feeds.findOne {owner: owner}, {'_id':1}, (err, feed) =>
      #   unless err
      #     criteria =
      #       targetName: "CActivity"
      #       targetId: activity._id
      #       sourceName: "JFeed"
      #       sourceId: feed._id

      #     @relationships.update criteria, criteria, {upsert:true}
    

