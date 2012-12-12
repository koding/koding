{argv} = require 'optimist'

koding = require './bongo'
koding.connect()

{authWorker:{authResourceName}} = require argv.c

console.log authResourceName

authExchangeOptions = {type: 'fanout', autoDelete: yes}

joinBongoClient =(data, routingKey)->
  console.log 'join bongo client', arguments
  # TODO: authenticate the bongo client

joinKiteClient =(data, routingKey)->
  console.log 'join kite client', arguments
  # TODO: authenticate the kite client

rejectClient =(routingKey)->
  console.log 'routingkey', routingKey
  koding.respondToClient routingKey, {error: 'Access denied'}

joinClient =(data)->
  {channel, routingKey} = data
  if channel is koding.resourceName
    joinBongoClient data, routingKey
  else if /^kite-\./.test channel
    joinKiteClient data, routingKey
  else
    rejectClient routingKey

koding.mq.ready ->
  {connection} = koding.mq
  connection.exchange authResourceName, authExchangeOptions, (authExchange)->
    connection.queue authResourceName, (authQueue)->
      authQueue.bind authExchange, ''
      authQueue.bind authExchange, ''
      authQueue.on 'queueBindOk', ->
        authQueue.subscribe (message, headers, deliveryInfo)->
          {routingKey} = deliveryInfo
          switch routingKey
            when 'client.auth'
              joinClient JSON.parse("#{message.data}")
            else rejectClient routingKey
