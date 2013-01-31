nodePath    = require 'path'
Bongo       = require 'bongo'
Broker      = require 'broker'
{argv}      = require 'optimist'
{extend}    = require 'underscore'

{mongo, mq, projectRoot, authWorker} = require('koding-config-manager').load("main.#{argv.c}")

mongo += '?auto_reconnect'

mqOptions = extend {}, mq
mqOptions.login = authWorker.login if authWorker?.login?

module.exports = new Bongo {
  mongo
  models: [
    'workers/social/lib/social/models/session.coffee'
    # 'workers/social/lib/social/models/account.coffee'
    # 'workers/social/lib/social/models/guest.coffee'
  ].map (path)-> nodePath.join projectRoot, path
  mq: new Broker mqOptions
  resourceName: authWorker.queueName
}