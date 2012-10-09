log = -> logger.info arguments...

{argv} = require 'optimist'

{exec} = require 'child_process'

process.on 'uncaughtException', (err)->
  exec './beep'
  console.log err, err?.stack

if require("os").platform() is 'linux'
  require("fs").writeFile "/var/run/node/koding.pid",process.pid,(err)->
    if err?
      console.log "[WARN] Can't write pid to /var/run/node/kfmjs.pid. monit can't watch this process."

Bongo = require 'bongo'
Broker = require 'broker'

Object.defineProperty global, 'KONFIG', value: require './config'
{mq, mongo, email} = KONFIG

EXCHANGE_PREFIX = "followable-"

{distributeActivityToFollowers, assureExchangeMesh} = require "./feeder"
distributeActivityToFollowers
  mq: mq
  mongo: mongo
  exchangePrefix: EXCHANGE_PREFIX

{Relationship} = require 'jraphical'

koding = new Bongo
  root        : __dirname
  mongo       : mongo
  models      : './models'
  queueName   : 'koding-social'
  mq          : new Broker mq
  fetchClient :(sessionToken, callback)->
    koding.models.JUser.authenticateClient sessionToken, (err, account)->
      if err
        koding.emit 'error', err
      else
        callback {sessionToken, connection:delegate:account}

handleClient = do ->
  clients = {}
  {mq} = koding
  {CActivity, JTag, JAccount, JFeed} = koding.models

  getOwnExchangeName = (account) ->
    "#{EXCHANGE_PREFIX}#{account._id}"

  getExchange = (exchangeName) ->
    mq.connection.exchanges[exchangeName]

  getWorkerQueueName = () -> "koding-feeder"

  bindToWorkerQueue = (exchangeName, callback) ->
    workerQueueOptions =
      exchangeAutoDelete: false
      queueExclusive: false
    # This effectively declares own exchange.
    mq.bindQueue(
      getWorkerQueueName(), 
      exchangeName, 
      "#.activity", 
      workerQueueOptions,
      callback
    )

  prepareBroker = (account) ->
    ownExchangeName = getOwnExchangeName account
    bindToWorkerQueue ownExchangeName

  handleFolloweeActivity = (account) ->
    ownExchangeName = getOwnExchangeName account
    ownExchange = getExchange ownExchangeName
    # When client logs in, listen to message from own exchange and
    # publish followees' activies to own exchange on a different
    # routing so that worker queue can consume from it.
    mq.on(
      ownExchangeName,
      "#.activity", 
      ownExchangeName, 
      (message, headers, deliveryInfo) ->
        publisher = deliveryInfo.exchange
        unless publisher is getOwnExchangeName account
          activityId = Bongo.ObjectId message
          CActivity.one {_id: activityId}, (err, activity) ->
            #ownExchange.publish "activityOf.#{publisher}", message, {deliveryMode: 2}
            account.emit "FollowedActivityArrived", activity
    )

  handleOwnActivity = (account) ->
    ownExchangeName = getOwnExchangeName account
    ownExchange = getExchange ownExchangeName
    activityTypes = ['CStatusActivity','CCodeSnipActivity','CDiscussionActivity','COpinionActivity']
    # Listen to when an activity is posted and publish own activity to MQ
    CActivity.on "ActivityIsCreated", (activity) ->
      return unless activity.type in activityTypes
      unless account.getId().toString() is activity.originId.toString()
        console.log "other feed"
      else
        options = deliveryMode: 2
        payload = activity._id.toString()
        # Publish to all user's folowers' feeds
        ownExchange.publish "#{ownExchangeName}.activity", payload, options

        # Publish to all mentioned topics' followers' feeds
        activity.fetchTeaser (err, {tags}) ->
          return unless tags?
          for tag in tags
            do ->
              exchangeName = getOwnExchangeName tag
              bindToWorkerQueue exchangeName, ->
                mq.createExchange exchangeName, {autoDelete: false}, (tagExchange) ->
                  tagExchange.publish "#{exchangeName}.activity", payload, options
  
  handleFollowAction = (account) ->
    ownExchangeName = getOwnExchangeName account
    # Receive when the account follows somebody
    mq.on "event-"+account.getId(), "FollowCountChanged", (data) ->
      # data are a list of arguments
      {action, followee, follower} = data[0]
      return unless followee?
      return unless action is "follow" or action is "unfollow"
      # contructor.name
      # Set up the exchange-to-exchange binding for followings.
      # followee can be JAccount, JTag, or JStatusUpdate.
      followeeNick = "#{EXCHANGE_PREFIX}#{followee._id}"
      routingKey = "#{followeeNick}.activity"
      method = "#{action.replace 'follow', 'bind'}Exchange"
      mq[method] {name:ownExchangeName}, {name:followeeNick}, routingKey

  (account) ->
    nickname = account.profile.nickname
    return if clients[nickname]

    feed = {title:"followed", description: ""}
    JFeed.assureFeed account, feed, (err, theFeed) ->

    clients[nickname] = account
    prepareBroker account
    handleFolloweeActivity account
    handleOwnActivity account
    handleFollowAction account

koding.on 'auth', (exchange, sessionToken)->
  koding.fetchClient sessionToken, (client)->
    {delegate} = client.connection

    unless delegate instanceof koding.models.JGuest
      handleClient delegate
    else
      koding.models.JAccount.once "AccountLoggedIn", (account) ->
        handleClient account

    koding.handleResponse exchange, 'changeLoggedInState', [delegate]

koding.connect console.log

console.log 'Koding Social Worker has started.'
