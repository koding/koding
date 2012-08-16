process.env['NODE_PATH'] = "#{process.cwd()}:#{process.cwd()}/node_modules"

try
  express           = require "express"
  {check, validate} = require "validator"
  _                 = require "underscore"
  traverse          = require "traverse"
  nodeRequest       = require "request"
  nodemailer        = require "nodemailer"
  # inspect           = require "inspect"
  JSONH             = require "jsonh"
  log4js            = require "log4js"
  logger            = log4js.getLogger "[KodingServer]"
  everyauth         = require "everyauth"
  http              = require "http"
  url               = require "url"
  oauth             = require "node-oauth"
  {DropboxClient}   = require "dropbox"
  bongo             = require "bongo"
  mongodb           = require 'mongodb'
  jraphical         = require "jraphical"
  hat               = require "hat"
  gzippo            = require "gzippo"
  os                = require "os"
  Pusher            = require 'node-pusher'
  postmark          = require('postmark') 'd79ad9bc-46cb-457f-b70c-a9785954bfb8'
  dateFormat        = require 'dateformat'
  bitly             = new (require "bitly")('kodingen','R_677549f555489f455f7ff77496446ffa')
  Broker            = require "broker"
  
  ###bongo.mq = bongo.Base::mq = switch process.argv[3]
    when 'beta'
      new Pusher
        appId   : 18240
        key     : 'a19c8bf6d2cad6c7a006'
        secret  : '51f7913fbb446767a9fb'
    else
      new Pusher
        appId   : 22120
        key     : 'a6f121a130a44c7f5325'
        secret  : '9a2f248630abaf977547'###
  #bongo.mq = bongo.Base::mq = new Broker({host: "localhost"})
  bongo.mq = bongo.Base::mq = new Broker({
    host: "web0.beta.system.aws.koding.com",
    login: "guest",
    password: "x1srTA7!%Vb}$n|S"
  });

catch err
  console.log "Build failed!  Missing dependency! (You may have the wrong version!)"
  throw err
  process.exit()