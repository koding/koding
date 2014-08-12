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