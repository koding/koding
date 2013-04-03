{argv}   = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

amqp = require 'amqp'
bongo = require './../../server/lib/server/bongo'
{JKiteCall, JAccount, JMemberKite} = bongo.models

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
                rawMessage = message?.data?.toString()
                if rawMessage
                  msg = JSON.parse rawMessage
                  if msg?.arguments?[0]
                    info = msg.arguments[0]

                    if info?
                      deliveryKey = deliveryInfo.routingKey.split '.'

                      JKiteCall.inc {
                        username : deliveryKey[2],
                        kiteName : info.kiteName,
                        methodName : info.method
                      },(err, kiteCall) =>
                        if err then console.log e.message
                        else
                          JAccount.one { 'profile.nickname' : kiteCall.username }, (err, user) =>

                            if err then console.log err.message
                            else

                              targetSelector =
                                status : 'active'
                                key    : info.withArgs.key

                              selector =
                                targetId   : user._id
                                sourceName : 'JMemberKite'
                                as         : 'owner'

                              options   =
                                targetOptions : { selector: targetSelector }

                              JMemberKite.fetcher selector, options, (err, activeKites) =>
                                console.log activeKites.length

                              # @TODO add count checking here, now couldnt manage
                              # to fetch expected result with above qury

                          console.log 'incremented count\n'

                      console.log "name    : #{info.kiteName}"
                      console.log "method  : #{info.method}"
                      console.log "args    :", info.withArgs
                      console.log "username: #{deliveryKey[2]}"
                      console.log "kite    : #{deliveryKey[3]}"
              catch e
                console.log e.message

__start KONFIG.mq