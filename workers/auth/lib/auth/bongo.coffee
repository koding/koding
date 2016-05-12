nodePath    = require 'path'
Bongo       = require 'bongo'
Broker      = require 'broker'
{ extend }  = require 'underscore'

KONFIG = require 'koding-config-manager'

{ mq, projectRoot, authWorker } = KONFIG

mongo = "mongodb://#{KONFIG.mongo}"

mqOptions = extend {}, mq
mqOptions.login = authWorker.login if authWorker?.login?

module.exports = new Bongo {
  mongo
  root: projectRoot
  models: 'workers/social/lib/social/models'
  mq: new Broker mqOptions
  resourceName: authWorker.queueName
}
