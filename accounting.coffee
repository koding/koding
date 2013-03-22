{argv}   = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

amqp = require 'amqp'
bongo = require './server/lib/server/bongo'
{JKiteApp} = bongo.models

__start = (config)->

    @connection       = amqp.createConnection config
    @connection.on 'error', (e)->
      console.error "An error occured while AMQP connection! #{e.message}"
    @connection.on 'ready', =>
      @connection.exchange 'accounting', { type : 'topic', autoDelete : no, durable : yes, exclusive : no }, (accounting) =>
        @connection.queue '', {exclusive: yes}, (queue)=>

          queue.bind accounting, '#', ''
          queue.on 'queueBindOk', =>
            queue.subscribe (message, headers, deliveryInfo)=>
              try
                rawMessage = message?.data?.toString() #, headers, deliveryInfo 
                if rawMessage
                  msg = JSON.parse rawMessage
                  if msg?.arguments?[0]
                    info = msg.arguments[0]

                    if info?
                      JKiteApp.inc { appKey : info.withArgs.key, methodName : info.method }, () => 
                        console.log 'incremented count\n'
                      console.log "name    : #{info.kiteName}"
                      console.log "method  : #{info.method}"
                      console.log "args    : #{info.withArgs.key}"
                      deliveryKey = deliveryInfo.routingKey.split '.'
                      console.log "username: #{deliveryKey[2]}"
                      console.log "kite    : #{deliveryKey[3]}"
              catch e
                console.log e.message

__start KONFIG.mq