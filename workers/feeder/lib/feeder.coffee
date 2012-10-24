SOCIALPATH = "../../social/lib/social"
CActivity = require "#{SOCIALPATH}/models/activity/index"
{ObjectId} = require 'bongo'

{EventEmitter} = require 'microemitter'

EventEmitter class Feeder
  EventEmitter @::

  getRoutingKey =(inst, event)-> "oid.#{inst._id}.event.#{event}"

  constructor: (options) ->
    {@mq, @queueName, @exchangePrefix} = options
    @queueName ?= "koding-feeder"
    @exchangePrefix ?= "followable-"
    @clients = {}

    @mq.ready =>
      @mq.on 'event-JAccount', "AccountAuthenticated", (account) =>
        @handleFolloweeActivity account

      @mq.on 'event-CActivity', "ActivityIsCreated", (activity) =>
        @handleNewActivity activity

      @mq.on 'event-JAccount', "FollowingRelationshipChanged", (data) =>
        {action, follower, followee} = data
        @handleFollowAction action, follower, followee

  # handleAccount: (account) ->
  #   client = account?.profile?.nickname
  #   unless @clients[client]?
  #     @clients[client] = account
  #     @handleFolloweeActivity account
  #     #@handleFollowAction account

  ###
  # Whenever an activity is created, it will just emit to the user's
  # exchange as well of the exchanges of any tags in the activity.
  # Messages will end up in the worker queue and be processed one by
  # one in round-robin fashion.
  ###
  handleNewActivity: (activity) ->
    activityTypes = ['CStatusActivity','CCodeSnipActivity','CDiscussionActivity','COpinionActivity']
    return unless activity.type in activityTypes
    accountId = activity.originId
    accountXName = @getExchangeName accountId

    #console.log "Feeder receives activity from #{accountId}"

    # Setting deliveryMode to 2 makes the message persistent.
    deliveryMode = 2
    autoDelete = no
    payload = activity._id.toString()

    @bindToWorkerQueue accountXName, =>
      @emitActivity accountXName, payload, {deliveryMode, autoDelete}

    try
      {tags} = JSON.parse activity.snapshot
      return unless tags?
      for tag in tags
        do =>
          tagXName = @getExchangeName tag._id
          @bindToWorkerQueue tagXName, =>
            @emitActivity tagXName, payload, {deliveryMode, autoDelete}
    catch e

  handleFollowAction: (action, follower, followee) ->
    # Receive when the account follows somebody
    return unless action is "follow" or action is "unfollow"
    # Set up the exchange-to-exchange binding for followings.
    # followee can be JAccount, JTag, or JStatusUpdate.
    followeeX = @getExchangeName followee
    followerX = @getExchangeName follower
    routingKey = "#{followeeX}.activity"
    method = "#{action.replace 'follow', 'bind'}Exchange"

    @mq[method] {name:followerX}, {name:followeeX}, routingKey

  # For real-time update of followed activities
  handleFolloweeActivity: (account) ->
    ownExchangeName = @getExchangeName account._id
    # Need to close the channel first
    @mq.connection.queues[ownExchangeName]?.close()
    # Then destroy the queue
    @mq.connection.queues[ownExchangeName]?.destroy()

    @mq.createExchange ownExchangeName, {autoDelete: no}, =>
      @mq.on(
        ownExchangeName,
        "#.activity", 
        ownExchangeName, 
        (message, headers, deliveryInfo) =>
          publisher = deliveryInfo.exchange
          unless publisher is ownExchangeName
            activityId = ObjectId message
            # CActivity.one {_id: activityId}, (err, activity) =>
              #ownExchange.publish "activityOf.#{publisher}", message, {deliveryMode: 2}
            @emit account, "FollowedActivityArrived", activityId
      )

  # handleFolloweeActivity: (account) ->
  #   ownExchangeName = @getExchangeName account._id
  #   @mq.createExchange ownExchangeName, {autoDelete: no}, =>
  #     @mq.on(
  #       ownExchangeName,
  #       "#.activity", 
  #       ownExchangeName, 
  #       (message, headers, deliveryInfo) =>
  #         publisher = deliveryInfo.exchange
  #         unless publisher is ownExchangeName
  #           activityId = ObjectId message
  #           # CActivity.one {_id: activityId}, (err, activity) =>
  #             #ownExchange.publish "activityOf.#{publisher}", message, {deliveryMode: 2}
  #           @emit account, "FollowedActivityArrived", activityId
  #     )

  # HELPERS #
  bindToWorkerQueue: (exchangeName, callback) ->
    workerQueueOptions =
      exchangeAutoDelete: no
      queueExclusive: no
      queueAutoDelete: no
      
    @mq.bindQueue(
      @queueName, 
      exchangeName, 
      "#.activity", 
      workerQueueOptions,
      (queue, exchangeName) ->
        queue.close()
        callback()
    )

  emitActivity: (exchangeName, payload, options) ->
    @mq.emit exchangeName, "#{exchangeName}.activity", payload, options

  on: (inst, event, callback) ->
    routing = getRoutingKey inst event
    opts = {exchangeAutoDelete: no}
    @mq.bindQueue "", "updateInstances", routing, opts, (queue) =>
      #@mq.on "updateInstances", routing, (payload) =>
      queue.subscribe (payload) =>
        message = @mq.cleanPayload payload
        callback message

  emit: (inst, event, payload) ->
    routing = getRoutingKey inst, event
    @mq.emit "updateInstances", routing, payload, {autoDelete:no}

  getExchange: (name) -> @mq.connection.exchanges[name]
  getExchangeName: (id) -> "#{@exchangePrefix}#{id}"

module.exports = Feeder

