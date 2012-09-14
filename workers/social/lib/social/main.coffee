log = -> logger.info arguments...

{argv} = require 'optimist'

# Error.stackTraceLimit = 100

{exec} = require 'child_process'

if process.argv[5] is "true"
  __runCronJobs   = yes
  log "--cron is active, cronjobs will be running with your server."


process.on 'uncaughtException', (err)->
  exec './beep'
  console.log err, err?.stack


# dbCallback= (err)->
#   if err
#     log err
#     log "database connection couldn't be established - abort."
#     process.exit()

if require("os").platform() is 'linux'
  require("fs").writeFile "/var/run/node/koding.pid",process.pid,(err)->
    if err?
      console.log "[WARN] Can't write pid to /var/run/node/kfmjs.pid. monit can't watch this process."

dbUrl = switch argv.d or 'mongohq-dev'
  when "local"
    "mongodb://localhost:27017/koding?auto_reconnect"
  when "sinan"
    "mongodb://localhost:27017/kodingen?auto_reconnect"
  when "vpn"
    "mongodb://kodingen_user:Cvy3_exwb6JI@10.70.15.2:27017/kodingen?auto_reconnect"
  when "beta"
    "mongodb://beta_koding_user:lkalkslakslaksla1230000@localhost:27017/beta_koding?auto_reconnect"
  when "beta-local"
    "mongodb://beta_koding_user:lkalkslakslaksla1230000@web0.beta.system.aws.koding.com:27017/beta_koding?auto_reconnect"
  when "wan"
    "mongodb://kodingen_user:Cvy3_exwb6JI@184.173.138.98:27017/kodingen?auto_reconnect"
  when "mongohq-dev"
    "mongodb://dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect"

Bongo = require 'bongo'
Broker = require 'broker'

koding = new Bongo
  mongo   : dbUrl
  models  : require('path').join __dirname, './models'
  queueName: 'koding-social'
  fetchClient:(sessionToken, callback)->
    koding.models.JUser.authenticateClient sessionToken, (err, account)->
      if err
        koding.emit 'error', err
      else
        callback {connection:delegate:account}
  mq      : new Broker {
    host      : "localhost"
    login     : "guest"
    password  : "guest"
    #host      : "web0.beta.system.aws.koding.com"
    #login     : "guest"
    #password  : "x1srTA7!%Vb}$n|S"
  }
koding.on 'auth', (exchange, sessionToken)->
  koding.fetchClient sessionToken, (client)->
    {delegate} = client.connection
    {nickname} = delegate.profile
    ownExchange = "x#{nickname}"
    # When client logs in, create own queue to consume real-time updates
    koding.mq.bindQueue ownExchange, ownExchange, '#'

    delegate.on "FollowCountChanged", ({follower, action}) =>
      return unless action is "follow" or "unfollow"
      # Set up the exchange-to-exchange binding for followings.
      followerNick = follower.profile.nickname
      routingKey = "#{followerNick}.activity"
      method = "#{action.replace 'follow', 'bind'}Exchange"
      mq[method] ownExchange, "x#{followerNick}", routingKey

    koding.handleResponse exchange, 'changeLoggedInState', [delegate]
koding.connect console.log