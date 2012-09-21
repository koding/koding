module.exports = class Feeder
  Broker = require 'broker'
  mongo = require 'mongoskin'

  constructor: (options = {}) ->
    options.host ?= "localhost"
    options.login ?= "guest"
    options.password ?= "guest"
    @mq = new Broker options

    @exchangePrefix = options.exchangePrefix ? "x"

    dbUrl = options.mongo ? "mongodb://dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect"
    db = mongo.db dbUrl
    @feeds = db.collection 'jFeeds'
    @relationships = db.collection 'relationships'

    @mq.subscribe "koding-feeder", {exclusive: false}, (message, headers, deliveryInfo) =>
      # The message will come from feed's owner's exchange with the routing
      # key of format "activityOf.#{followee}", payload is the activity.
      {exchange, routingKey, _consumerTag} = deliveryInfo
      activity = JSON.parse message

      regEx = new RegExp "^#{@exchangePrefix}"
      owner = exchange.replace regEx, ""

      @feeds.findOne {owner: owner}, {'_id':1}, (err, feed) =>
        unless err
          criteria =
            targetName: "CActivity"
            targetId: activity._id
            sourceName: "JFeed"
            sourceId: feed._id

          @relationships.update criteria, criteria, {upsert:true}
    

