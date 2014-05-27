{argv} = require 'optimist'

koding = require './bongo'
koding.connect()

GuestCleanerWorker = require './guestcleanerwoker'

{guestCleanerWorker} = require('koding-config-manager').load("main.#{argv.c}")

processMonitor = (require 'processes-monitor').start
  name : "Guest Cleaner Worker #{process.pid}"
  stats_id: "worker.guestcleaner." + process.pid
  interval : 30000

guestCleanerhWorker = new GuestCleanerWorker koding, guestCleanerWorker
guestCleanerhWorker.init()

log4js  = require 'log4js'
logger  = log4js.getLogger('guestCleaner')

log4js.configure {
  appenders: [
    { type: 'console' }
    { type: 'file', filename: 'logs/guestCleaner.log', category: 'guestCleaner' }
    { type: "log4js-node-syslog", tag : "guestCleaner", facility: "local0", hostname: "localhost", port: 514 }
  ],
  replaceConsole: true
}
