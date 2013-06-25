{argv}   = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")

amqp = require 'amqp'
bongo = require './../../server/lib/server/bongo'
{JKiteCall, JAccount, JMemberKite} = bongo.models

controlCallCount = (info, kiteCall) =>
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

      # @TODO add count checking here, now couldnt manage
      # to fetch expected result with above qury

      JMemberKite.fetcher selector, options, (err, memberKite) =>
        if err then console.log err.message
        else
          console.log memberKite.length

          if memberKite.count >= kiteCall.count
            memberKite.update {$set: 'status': 'passive'} , (err) =>

incrementCallCount = (deliveryKey, info) =>

  JKiteCall.inc {
      username : deliveryKey[2],
      kiteName : info.kiteName,
      methodName : info.method
    },(err, kiteCall) =>
      if err then console.log e.message
      else
        #controlCallCount(info, kiteCall)
        console.log 'incremented count\n'

accountant = (message, headers, deliveryInfo) =>
  try
    rawMessage = message?.data?.toString()
    if rawMessage
      msg = JSON.parse rawMessage
      if msg?.arguments?[0]
        info = msg.arguments[0]

        if info?
          deliveryKey = deliveryInfo.routingKey.split '.'

          incrementCallCount(deliveryKey, info)

          console.log "name    : #{info.kiteName}"
          console.log "method  : #{info.method}"
          console.log "args    :", info.withArgs
          console.log "username: #{deliveryKey[2]}"
          console.log "kite    : #{deliveryKey[3]}"
  catch e
    console.log e.message

start = (config)=>

    @connection       = amqp.createConnection config
    @connection.on 'error', (e)->
      console.error "An error occured while AMQP connection! #{e.message}"
    @connection.on 'ready', =>
      @connection.exchange 'accounting', { type : 'topic', autoDelete : no, durable : yes, exclusive : no }, (accounting) =>
        @connection.queue '', {exclusive: yes}, (queue)=>
          queue.bind accounting, '#', ''
          queue.on 'queueBindOk', =>
            queue.subscribe (message, headers, deliveryInfo) =>
              accountant message, headers, deliveryInfo

start KONFIG.mq