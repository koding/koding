{ObjectId} = require 'bongo'
mongoskin = require 'mongoskin'
Broker = require 'broker'
{daisy} = require 'sinkrow'
assert = require 'assert'

JAccount = require '../../social/lib/social/models/account'
Feeder = require '../lib/feeder'

testAccount = "507c91fe765a249d7c000003"
followerAccount = "502348600a6f5e381a000005"
followerFeed = "50709250849a6e0b61000003"
testActivity = "507c9353765a249d7c00001a"
testWorkerQueue = "test-feeder-queue"
exchangePrefix = "followable-"

mockActivity =
  _id: ObjectId testActivity
  type: "CStatusActivity"
  originId: ObjectId testAccount
  fetchTeaser: (callback) ->
    callback null, {}

mockActivityWithTags =
  _id: ObjectId testActivity
  type: "CStatusActivity"
  originId: ObjectId testAccount
  fetchTeaser: (callback) ->
    tags = [{_id: "tag1"}, {_id: "tag2"}]
    callback null, {tags}

broker = new Broker
  host: "localhost"
  login: "guest"
  password: "guest"
  vhost: "/"

db = mongoskin.db "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"
JAccount.setClient db

feeder = new Feeder
  mq            : broker
  queueName     : testWorkerQueue
  exchangePrefix: exchangePrefix

setUp = (callback) ->
  opts = {durable:true, exclusive:false}
  broker.createQueue testWorkerQueue, opts, callback

daisy tasks = [
  ->
    console.log "Test that feeder can handle new activity"
    setUp (queue) ->
      queue.subscribe (m, h, d) ->
        {exchange, routingKey, consumerTag} = d
        message = m.data+"" if m.data?
        console.log "#1 - Checking that the message is the activity's id"
        assert.equal message, testActivity, "should receive the correct activity"
        console.log "#1 - Passed."

        regEx = new RegExp "^#{exchangePrefix}"
        ownerString = exchange.replace regEx, ""
        console.log "#2 - Checking that the message is from test account's exchange"
        assert.equal ownerString, testAccount, "should from the test account's exchange"
        console.log "#2 - Passed."

        console.log "This test case passed!"
        # Clean up
        queue.close()
        tasks.next()
      .addCallback (ok) ->
        feeder.handleNewActivity mockActivity

  ->
    console.log "Test that feeder also publishes to the topics in activity"
    setUp (queue) ->
      expected = [testAccount, "tag1", "tag2"]
      currentIdx = 0
      messages = {}
      queue.subscribe {ack:true, prefetchCount:1}, (m, h, d) ->
        {exchange, routingKey, consumerTag} = d
        message = m.data+"" if m.data?
        regEx = new RegExp "^#{exchangePrefix}"
        ownerString = exchange.replace regEx, ""
        messages[ownerString] = message
        currentIdx++
        queue.shift()

        if currentIdx is expected.length
          #queue.unsubscribe consumerTag
          queue.close()

          console.log "Checking received messages"
          for key of messages
            console.log "Message on exchange #{key}"
            assert.equal (key in expected), true, "should receive valid key"
            # console.log "Message should be from the exchange of #{expectedOwner}"
            console.log "Message should be the #{testActivity}"
            assert.equal messages[key], testActivity

          console.log "This test case passed!"
          tasks.next()

      .addCallback (ok) ->
        feeder.handleNewActivity mockActivityWithTags

  ->
    console.log "Test exchange bindings when follow"
    getRoutingKey =(inst, event)-> "oid.#{inst._id}.event.#{event}"
    JAccount.one {_id: ObjectId(followerAccount)}, (err, follower) ->
      feeder.handleAccount follower
      
      # Actual tests
      routing = getRoutingKey(follower, "FollowedActivityArrived")
      broker.on "updateInstances", routing, (activity) ->
      #follower.on "FollowedActivityArrived", (activity) ->
        console.log "Make sure that the follower receive the activity"
        assert activity._id, testActivity, "should be same activity id"

        console.log "This test case passed"
        tasks.next()

      # Setting up
      followData =
        action: "follow"
        followee: {_id: ObjectId testAccount}

      setTimeout ->
        # Emit the event so that the e2e binding is established.
        routing = getRoutingKey(follower, "FollowCountChanged")
        broker.emit "updateInstances", routing, followData, {autoDelete:false}
        #follower.emit "FollowCountChanged", followData
      , 1000

      setTimeout ->
        # Call handleNewActivity to emit to the test account's exchange.
        # The activity should be forwarded to follower account's exchange,
        # then the follower account should emit "FollowedActivityArrived".
        feeder.handleNewActivity mockActivity
      , 1000

]