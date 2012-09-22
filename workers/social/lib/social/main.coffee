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

Object.defineProperty global, 'KONFIG', value: require './config'
{mq, mongo, email} = KONFIG

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

Feeder = require './feeder'
feeder = new Feeder

koding.on 'auth', (exchange, sessionToken)->
  koding.fetchClient sessionToken, (client)->
    {delegate} = client.connection
    {nickname} = delegate.profile

    ownExchangeName = "x#{nickname}"
    # When client logs in, create own queue to consume real-time updates
    koding.mq.bindQueue ownExchangeName, ownExchangeName, '#', {exchangeAutoDelete: false}
    # Bind to feed worker queue
    workerQueueOptions =
      exchangeAutoDelete: false
      queueExclusive: false
    koding.mq.bindQueue "koding-feeder", ownExchangeName, "#.activity", workerQueueOptions

    # Listen to when an activity is posted and publish it to MQ
    koding.models.CActivity.on "feed.new", ([model]) ->
      options = deliveryMode: 2

      ownExchange= koding.mq.connection.exchanges[ownExchangeName]
      payload = JSON.stringify model
      ownExchange.publish "#{ownExchangeName}.activity", payload, options

    delegate.on "FollowCountChanged", () ->
      console.log "FollowCountChanged", arguments
      return unless action? is "follow" or "unfollow"
      # Set up the exchange-to-exchange binding for followings.
      followerNick = follower.profile.nickname
      routingKey = "#{followerNick}.activity"
      method = "#{action.replace 'follow', 'bind'}Exchange"
      koding.mq[method] ownExchangeName, "x#{followerNick}", routingKey

    koding.handleResponse exchange, 'changeLoggedInState', [delegate]

koding.connect console.log

console.log 'Koding Social Worker has started.'
