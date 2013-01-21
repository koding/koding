mongoskin = require 'mongoskin'
Broker = require 'broker'
processes = new (require 'processes')
{ObjectId} = require 'bongo'
{daisy} = require 'sinkrow'

WORKER_QUEUE = "koding-feeder"
WORKER_NAME = "feedWorker"
PREFIX = "followable-"

testAccount = "507c91fe765a249d7c000003"
followerAccount = "502348600a6f5e381a000005"
followerFeed = "50709250849a6e0b61000003"
testActivity = "507c9353765a249d7c00001a"

#[{"bongo_":{"constructorName":"CStatusActivity","instanceId":"fdd8a360b965cac858e21b9ddf0f6089"},"_events":{},"data":{"modifiedAt":"2012-10-15T22:50:59.615Z","type":"CStatusActivity","originId":"507c91fe765a249d7c000003","originType":"JAccount","_id":"507c9353765a249d7c00001a","sorts":{"repliesCount":0,"likesCount":0,"followerCount":0},"createdAt":"2012-10-15T22:50:59.032Z"},"sorts":{"repliesCount":0,"likesCount":0,"followerCount":0},"createdAt":"2012-10-15T22:50:59.032Z","modifiedAt":"2012-10-15T22:50:59.615Z","originType":"JAccount","originId":"507c91fe765a249d7c000003","type":"CStatusActivity","_id":"507c9353765a249d7c00001a"}]

processes.fork
  name  : WORKER_NAME
  modulePath : "../lib/worker"
  opts  : silent : yes
  restart : yes
  restartInterval : 1000
  verbose : yes

broker = new Broker
  host: "localhost"
  login: "guest"
  password: "guest"
  vhost: "/"

db = mongoskin.db "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"
feeds = db.collection "jFeeds"
relationships = db.collection "relationships"

daisy queue = [
  ->
    p = processes.get WORKER_NAME
    console.log "Worker process is started at #{p.pid}"
    console.log "Trying to publish an arbitrary message to worker queue"
    broker.ready ->
      broker.connection.publish WORKER_QUEUE, "abc"
      p = processes.get WORKER_NAME
      console.log "Worker process should not be restarted and have same PID #{p.pid}"
      console.log "-------- END OF TEST --------"
      setTimeout ->
        queue.next()
      , 1000

  ->
    console.log "This test assumes that follower already followed test account"
    xName = "#{PREFIX}#{testAccount}"
    routing = "#{xName}.activity"
    criteria =
      targetName  : "CActivity"
      targetId    : ObjectId testActivity
      sourceName  : "JFeed"
      sourceId    : ObjectId followerFeed
      as          : "container"
    relationships.remove criteria, {safe:true}, () ->
      # There should not be test activity in follower's feed
      broker.emit xName, routing, testActivity
      setTimeout ->
        relationships.findOne criteria, (err, rel) ->
          if err
            console.log "Error finding the relationship: " + err
          else if not rel
            console.log "There is no relationship"
          else
            console.log "Relationship is stored correctly with id "+rel._id
          queue.next()
      , 5000

  ->
    console.log "TODO: Test that worker can receive next message"
    queue.next()
]