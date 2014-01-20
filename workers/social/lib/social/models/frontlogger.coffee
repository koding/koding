Bongo     = require "bongo"
jraphical = require 'jraphical'

{secure, signature} = Bongo

log4js  = require 'log4js'
logger  = log4js.getLogger('front')

log4js.configure {
  appenders: [
    { type: 'console' }
    { type: 'file', filename: 'logs/front.log', category: 'social' }
    { type: "log4js-node-syslog", tag : "front", facility: "local0", hostname: "localhost", port: 514 }
  ]
}

module.exports = class FrontLogger extends jraphical.Module
  @share()
  @set
    sharedMethods :
      static:
        trace:[
          (signature String)
          (signature String, Object)
        ]
        debug:[
          (signature String)
          (signature String, Object)
        ]
        info:[
          (signature String)
          (signature String, Object)
        ]
        warn:[
          (signature String)
          (signature String, Object)
        ]
        error:[
          (signature String)
          (signature String, Object)
        ]
        fatal:[
          (signature String)
          (signature String, Object)
        ]

  logMethods = ['trace', 'debug', 'info', 'warn', 'error', 'fatal']
  for method in logMethods
    do (method)=>
      @[method] = (message, params)->
        if params
          logger[method] message, params
        else
          logger[method] message
