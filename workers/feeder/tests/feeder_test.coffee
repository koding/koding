{ObjectId} = require 'bongo'
mongoskin = require 'mongoskin'
Broker = require 'broker'
{daisy} = require 'sinkrow'
assert = require 'assert'

CActivity = require '../../social/lib/social/models/activity/index'
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
      queue.subscribe {ack:true, prefetchCount:1}, (m, h, d) ->
        {exchange, routingKey, consumerTag} = d
        message = m.data+"" if m.data?
        regEx = new RegExp "^#{exchangePrefix}"
        ownerString = exchange.replace regEx, ""
        expectedOwner = expected[currentIdx]
        console.log "#"+currentIdx+" - Message should be from the exchange of #{expectedOwner}"
        assert.equal ownerString, expectedOwner, "should be from the exchange of #{expectedOwner}"
        console.log "#"+currentIdx+" - Passed."
        currentIdx++
        queue.shift()

        if currentIdx is expected.length
          console.log "This test case passed!"
          #queue.unsubscribe consumerTag
          queue.close()
          tasks.next()

      .addCallback (ok) ->
        feeder.handleNewActivity mockActivityWithTags

]