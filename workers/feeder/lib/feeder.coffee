SOCIALPATH = "../../social/lib/social"
CActivity = require "#{SOCIALPATH}/models/activity/index"
{ObjectId} = require 'bongo'
mongoskin = require 'mongoskin'

{EventEmitter} = require 'microemitter'

EventEmitter class Feeder
  EventEmitter @::

  getRoutingKey =(inst, event)-> "oid.#{inst._id}.event.#{event}"

  constructor: (options) ->
    {@mq, mongo, @queueName, @exchangePrefix} = options
    @mongo = mongoskin.db mongo
    @queueName ?= "koding-feeder"
    @exchangePrefix ?= "followable-"

    # Create this exchange beforehand so there is no precondition-failed.
    @mq.createExchange "updateInstances", {autoDelete:no}

    @mq.ready =>
      @mq.on 'event-CActivity', "ActivityIsCreated", (activity) =>
    # CActivity.setClient @mongo
    # CActivity.on "ActivityIsCreated", (activity) =>
        @handleNewActivity activity

  handleAccount: (account) ->
    @handleFolloweeActivity account
    @handleFollowAction account

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
    # Setting deliveryMode to 2 makes the message persistent.
    
    deliveryMode = 2
    autoDelete = no
    payload = activity._id.toString()

    @bindToWorkerQueue accountXName, =>
      @emitActivity accountXName, payload, {deliveryMode, autoDelete}

    activity.fetchTeaser (err, {tags}) =>
      return unless tags?
      for tag in tags
        do =>
          tagXName = @getExchangeName tag._id
          @bindToWorkerQueue tagXName, =>
            @emitActivity tagXName, payload, {deliveryMode, autoDelete}

  handleFollowAction: (account) ->
    ownExchangeName = @getExchangeName account._id
    # Receive when the account follows somebody
    @on account, "FollowCountChanged", (data) =>
    #account.on "FollowCountChanged", (data) =>
      # data are a list of arguments
      {action, followee} = data
      return unless followee?
      return unless action is "follow" or action is "unfollow"
      # contructor.name
      # Set up the exchange-to-exchange binding for followings.
      # followee can be JAccount, JTag, or JStatusUpdate.
      followeeNick = @getExchangeName followee._id
      routingKey = "#{followeeNick}.activity"
      method = "#{action.replace 'follow', 'bind'}Exchange"
      @mq[method] {name:ownExchangeName}, {name:followeeNick}, routingKey

  # For real-time update of followed activities
  handleFolloweeActivity: (account) ->
    ownExchangeName = @getExchangeName account._id
    @mq.createExchange ownExchangeName, {autoDelete: no}, =>
      @mq.on(
        ownExchangeName,
        "#.activity", 
        ownExchangeName, 
        (message, headers, deliveryInfo) =>
          publisher = deliveryInfo.exchange
          unless publisher is ownExchangeName
            activityId = ObjectId message
            CActivity.one {_id: activityId}, (err, activity) =>
              #ownExchange.publish "activityOf.#{publisher}", message, {deliveryMode: 2}
              @emit account, "FollowedActivityArrived", activity
      )

  # HELPERS #
  bindToWorkerQueue: (exchangeName, callback) ->
    workerQueueOptions =
      exchangeAutoDelete: no
      queueExclusive: no
    # This effectively declares own exchange.
    @mq.bindQueue(
      @queueName, 
      exchangeName, 
      "#.activity", 
      workerQueueOptions,
      callback
    )

  emitActivity: (exchangeName, payload, options) ->
    @mq.emit exchangeName, "#{exchangeName}.activity", payload, options

  on: (inst, event, listener) ->
    routing = "oid.#{inst._id}.event.#{event}"
    @mq.on "updateInstances", routing, listener

  emit: (inst, event, payload) ->
    routing = "oid.#{inst._id}.event.#{event}"
    @mq.emit "updateInstances", routing, payload


  getExchange: (name) -> @mq.connection.exchanges[name]
  getExchangeName: (id) -> "#{@exchangePrefix}#{id}"

module.exports = Feeder

