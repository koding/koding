process.title = 'koding-emailer'
EmailerWorker = require './emailerworker'

emailerWorker = new EmailerWorker
emailerWorker.start()
