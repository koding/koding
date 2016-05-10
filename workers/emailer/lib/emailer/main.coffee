process.title = 'koding-emailer'
EmailerWorker = require './emailerworker'

# expose healthcheck and version handlers
require('../../../runartifactserver')('emailerworker')

emailerWorker = new EmailerWorker
emailerWorker.start()
