log = -> logger.info arguments...

# Core Nodejs libraries:
{spawn, exec}   = require 'child_process'
# crypto          = require 'crypto'
# sys             = require 'sys'
fs              = require 'fs'
Path            = require 'path'
{EventEmitter}  = require 'events'

slice         = Array::slice
splice        = Array::splice
noop          = Function()

# Error.stackTraceLimit = 100

if process.argv[5] is "true"
  __runCronJobs   = yes
  log "--cron is active, cronjobs will be running with your server."


process.on 'uncaughtException', (err)->
  exec './beep'
  console.log err, err?.stack


dbCallback= (err)->
  if err
    log err
    log "database connection couldn't be established - abort."
    process.exit()


dbUrl = switch process.argv[3] or 'local'
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
    "mongodb://dev:GnDqQWt7iUQK4M@rose.mongohq.com:10084/koding_dev2?auto_reconnect"
    # "mongodb://dev:633939V3R6967W93A@alex.mongohq.com:10065/koding_copy?auto_reconnect"
  when "stage"
    "mongodb://koding_stage_user:dkslkds84ddj@web0.beta.system.aws.koding.com:38017/koding_stage?auto_reconnect"


console.log 'connecting to '+dbUrl
# log "connecting to #{dbUrl}"
#mongoose.connect dbUrl, dbCallback
bongo.setClient dbUrl
