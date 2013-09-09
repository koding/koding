{argv} = require 'optimist'

koding = require './bongo'
koding.connect()

EmailConfirmationChecker = require './emailconfirmationcheckerworker'

{librato, emailConfirmationCheckerWorker: config} = require('koding-config-manager').load("main.#{argv.c}")

processMonitor = (require 'processes-monitor').start
  name : "Email Confirmation Checker Worker #{process.pid}"
  stats_id: "worker.emailconfirmationchecker." + process.pid
  interval : 30000
  librato: librato

emailConfirmationCheckerWorker = new EmailConfirmationChecker koding, config
emailConfirmationCheckerWorker.init()
