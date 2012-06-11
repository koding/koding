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

if process.argv[5] is "true"
  __runCronJobs   = yes
  log "--cron is active, cronjobs will be running with your server."


process.on 'uncaughtException', (err)->
  console.log err.stack
  exec './beep'

#do ->
#  oldGetGroup = nowjs.getGroup
#  nowjs.getGroup = (groupName)->
#    oldGetGroup.call nowjs, groupName


config =
  SALT  : "xKokJE8bT7YAiMP"
  paths :
    user_root: "/Users/devrim"
  foreignProviders :
    dropbox:
      consumerKey    : 'pr6x4ms1vx39qt4'
      consumerSecret : 'eigbhfdlihe0w58'
      successPage    : '/successDropbox'
      failedPage     : '/failedDropbox'
      host           : 'http://local.host:3000'
    facebook :
      appId          : '232364750141667'
      appSecret      : '298535d8bf1abd4ecf41241bd5c2ed09'
      successPage    : '/successFacebook'
      failedPage     : '/failedFacebook'
    twitter   :
      consumerKey    : 'O0qS8vTxC4NXbqvKBUf6JQ'
      consumerSecret : 'KiUq9cfaSyfuG4UDPRpQNIwiHNr867VAm87njb9r2mI'
      successPage    : '/successTwitter'
      failedPage     : '/failedTwitter'
    google :
      appId          : '3335216477.apps.googleusercontent.com'
      appSecret      : 'PJMW_uP39nogdu0WpBuqMhtB'
      scope          : 'https://www.google.com/m8/feeds/'
      host           : 'http://localhost:3000'
      successPage    : '/successGoogle'
      failedPage     : '/failedGoogle'
    github :
      appId          : '016975dc6db0ae2bbe6f'
      appSecret      : '396e422a72a7f099b37e94b5a594d05a48216d14'
      successPage    : '/successGithub'
      failedPage     : '/failedGithub'
      karma :
        ref          : 'Public Repositories'
        path         : '/api/v2/json/user/show/{id}'
        host         : 'github.com'
        pathToKarma  : 'user.public_repo_count'
    stackoverflow :
      karma :
        gzipped      : yes
        ref          : 'Reputation Points'
        path         : '/1.1/users/{id}'
        host         : 'api.stackoverflow.com'
        pathToKarma  : 'users[0].reputation'
    # hackernews :
    #   karma:
    #     ref  : 'Karma Points'
    #     path : '/profile/{id}?format=json'
    #     host:  'api.ihackernews.com'
    #     # url  : 'http://api.ihackernews.com'
    #     pathToKarma : 'karma'

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
    #"mongodb://beta_koding_user::^j.tL9y8)f[zYGMZ@sysmongo.ct.dev.srv.kodingen.com/beta_koding"
  when "beta"
    "mongodb://beta_koding_user:lkalkslakslaksla1230000@db0.beta.system.aws.koding.com/beta_koding?auto_reconnect"
  when "wan"
    "mongodb://kodingen_user:Cvy3_exwb6JI@184.173.138.98:27017/kodingen?auto_reconnect"
  when "mongohq-dev"
    "mongodb://dev:YzaCHWGkdL2r4f@staff.mongohq.com:10016/koding?auto_reconnect"

# log "connecting to #{dbUrl}"
#mongoose.connect dbUrl, dbCallback
bongo.setClient dbUrl
