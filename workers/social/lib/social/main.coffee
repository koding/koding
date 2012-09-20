log = -> logger.info arguments...

{argv} = require 'optimist'

{exec} = require 'child_process'

if process.argv[5] is "true"
  __runCronJobs   = yes
  log "--cron is active, cronjobs will be running with your server."

process.on 'uncaughtException', (err)->
  exec './beep'
  console.log err, err?.stack

if require("os").platform() is 'linux'
  require("fs").writeFile "/var/run/node/koding.pid",process.pid,(err)->
    if err?
      console.log "[WARN] Can't write pid to /var/run/node/kfmjs.pid. monit can't watch this process."

# dbUrl = switch argv.d or 'mongohq-dev'
#   when "local"
#     "mongodb://localhost:27017/koding?auto_reconnect"
#   when "sinan"
#     "mongodb://localhost:27017/kodingen?auto_reconnect"
#   when "vpn"
#     "mongodb://kodingen_user:Cvy3_exwb6JI@10.70.15.2:27017/kodingen?auto_reconnect"
#   when "beta"
#     "mongodb://beta_koding_user:lkalkslakslaksla1230000@localhost:27017/beta_koding?auto_reconnect"
#   when "beta-local"
#     "mongodb://beta_koding_user:lkalkslakslaksla1230000@web0.beta.system.aws.koding.com:27017/beta_koding?auto_reconnect"
#   when "wan"
#     "mongodb://kodingen_user:Cvy3_exwb6JI@184.173.138.98:27017/kodingen?auto_reconnect"
#   when "mongohq-dev"
#     "mongodb://dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect"

Bongo = require 'bongo'
Broker = require 'broker'
{amqp, mongo, email} = require './config'

koding = new Bongo
  root        : __dirname
  mongo       : mongo
  models      : './models'
  queueName   : 'koding-social'
  mq          : new Broker amqp
  fetchClient :(sessionToken, callback)->
    koding.models.JUser.authenticateClient sessionToken, (err, account)->
      if err
        koding.emit 'error', err
      else
        callback {sessionToken, connection:delegate:account}

Feeder = require './feeder'
feeder = new Feeder

handleClient = do ->
  clients = {}

  handleFolloweeActivity = (account) ->
    ownExchangeName = "x#{account.profile.nickname}"
    # When client logs in, create own queue to consume real-time updates
    koding.mq.bindQueue ownExchangeName, ownExchangeName, '#', {exchangeAutoDelete: false}
    # Client will receive followee's post (not own) on client's queue, then
    # forward it to the worker queue by publishing to own exchange. The
    # worker queue is consuming from this exchange.
    ownExchange = koding.mq.connection.exchanges[ownExchangeName]
    koding.mq.subscribe ownExchangeName, (message, headers, deliveryInfo) =>
      publisher = deliveryInfo.exchange
      ownExchange.publish "feed", message, {deliveryMode: 2}

  handleOwnActivity = (account) ->
    # Listen to when an activity is posted and publish it to MQ
    koding.models.CActivity.on "feed.new", ([model]) ->
      console.log "account", account
      console.log model
      options = deliveryMode: 2
      payload = JSON.stringify model
      # ownExchange.publish "#{ownExchangeName}.activity", payload, options
  
  handleFollowAction = (account) ->
    account.on "FollowCountChanged", () ->
      console.log "FollowCountChanged111", arguments
      return unless action? is "follow" or "unfollow"
      # Set up the exchange-to-exchange binding for followings.
      followerNick = follower.profile.nickname
      routingKey = "#{followerNick}.activity"
      method = "#{action.replace 'follow', 'bind'}Exchange"
      koding.mq[method] ownExchangeName, "x#{followerNick}", routingKey

  (client) ->
    {delegate} = client.connection
    nickname = delegate.profile.nickname
    return if clients[nickname]
    clients[nickname] = client
    handleFolloweeActivity delegate
    handleOwnActivity delegate
    handleFollowAction delegate

koding.on 'auth', (exchange, sessionToken)->
  koding.fetchClient sessionToken, (client)->
    {delegate} = client.connection
    {nickname} = delegate.profile

    handleClient client

    # # Bind to feed worker queue
    # workerQueueOptions =
    #   exchangeAutoDelete: false
    #   queueExclusive: false
    # koding.mq.bindQueue "koding-feeder", ownExchangeName, "#.activity", workerQueueOptions

    koding.handleResponse exchange, 'changeLoggedInState', [delegate]

koding.connect console.log