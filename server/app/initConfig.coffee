log = -> logger.info arguments...

console.log "hello world8",process.pid

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

if process.argv[5] is "true"
  __runCronJobs   = yes
  log "--cron is active, cronjobs will be running with your server."


process.on 'uncaughtException', (err)->
  console.log err.stack
  exec './beep'


dbCallback= (err)->
  if err
    log err
    log "database connection couldn't be established - abort."
    process.exit()


dbUrl = switch process.argv[3] or 'local'
  when "local"
    "mongodb://localhost:27017/kodingen3?auto_reconnect"
  when "sinan"
    "mongodb://localhost:27017/kodingen?auto_reconnect"
  when "vpn"
    "mongodb://kodingen_user:Cvy3_exwb6JI@10.70.15.2:27017/kodingen?auto_reconnect"
    # "mongodb://kodingen_user:Cvy3_exwb6JI@sysmongo.ct.dev.srv.kodingen.com:27017/kodingen?auto_reconnect"
    # "mongodb://kodingen_user:Cvy3_exwb6JI@sysmongo.ct.dev.srv.kodingen.com:27017/kodingen?auto_reconnect"
    # "mongodb://kodingen_user:Cvy3_exwb6JI@184.173.138.98:27017/kodingen?auto_reconnect"
    # "mongodb://beta_koding_user::^j.tL9y8)f[zYGMZ@sysmongo.ct.dev.srv.kodingen.com/beta_koding"
  when "beta"
    "mongodb://beta_koding_user:lkalkslakslaksla1230000@db0.beta.system.aws.koding.com/beta_koding?auto_reconnect"
  when "wan"
    "mongodb://kodingen_user:Cvy3_exwb6JI@184.173.138.98:27017/kodingen?auto_reconnect"
  when "mongohq-dev"
    "mongodb://dev:YzaCHWGkdL2r4f@staff.mongohq.com:10016/koding?auto_reconnect"


console.log 'connecting to '+dbUrl
# log "connecting to #{dbUrl}"
#mongoose.connect dbUrl, dbCallback
bongo.setClient dbUrl
