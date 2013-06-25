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
  root: projectRoot
  models: [
    'workers/social/lib/social/models/session.coffee'
    'workers/social/lib/social/models/account'
    'workers/social/lib/social/models/group'
    'workers/social/lib/social/models/name.coffee'
    'workers/social/lib/social/models/vm.coffee'
    # 'workers/social/lib/social/models/guest.coffee'
  ]
  mq: new Broker mqOptions
  resourceName: authWorker.queueName
}