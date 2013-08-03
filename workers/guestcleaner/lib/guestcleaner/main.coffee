{argv} = require 'optimist'

koding = require './bongo'
koding.connect()

GuestCleanerWorker = require './guestcleanerwoker'

{librato, guestCleanerWorker} = require('koding-config-manager').load("main.#{argv.c}")

processMonitor = (require 'processes-monitor').start
  name : "Guest Cleaner Worker #{process.pid}"
  stats_id: "worker.guestcleaner." + process.pid
  interval : 30000
  librato: librato

guestCleanerhWorker = new GuestCleanerWorker koding, guestCleanerWorker
guestCleanerhWorker.init()
