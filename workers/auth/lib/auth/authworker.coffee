{EventEmitter} = require 'microemitter'

module.exports = class AuthWorker extends EventEmitter

  AuthedClient = require './authedclient'

  constructor:(@bongo, @resourceName)->
    @services = {}
    @clients  = {}
    @counts   = {}
    @routingKeysBySocketId = {}

    @addService
      serviceType : 'kite-webterm'
      serviceName : 'kite-webterm1'

  bound: require 'koding-bound'

  authenticate:(messageData, routingKey, callback)->
    {clientId, channel, event} = messageData
    @requireSession clientId, routingKey, callback

  requireSession:(clientId, routingKey, callback)->
    {JSession} = @bongo.models
    JSession.fetchSession clientId, (err, session)=>
      if err? or not session? then @rejectClient routingKey
      else
        tokenHasChanged = session.clientId isnt clientId
        @updateSessionToken session.clientId, routingKey  if tokenHasChanged
        callback session

  updateSessionToken:(clientId, routingKey)->
    @bongo.respondToClient routingKey,
      method      : 'updateSessionToken'
      arguments   : [clientId]
      callbacks   : {}

  getNextServiceName:(serviceType)->
    count = @counts[serviceType] ?= 0
    servicesOfType = @services[serviceType]
    console.log {servicesOfType, serviceType}
    return  unless servicesOfType?.length
    serviceName = servicesOfType[count % servicesOfType.length]
    @counts[serviceType] += 1
    return serviceName

  addService:({serviceType, serviceName})->
    servicesOfType = @services[serviceType] ?= []
    servicesOfType.push serviceName

  removeService:({serviceType, serviceName})->
    servicesOfType = @services[serviceType]
    index = servicesOfType.indexOf serviceName
    servicesOfType.splice index, 1

  addClient:(socketId, exchange, routingKey)->
    clientsBySocketId = @clients[socketId]
    clientsBySocketId = @clients[socketId] = []  unless clientsBySocketId?
    clientsBySocketId.push new AuthedClient {routingKey, socketId, exchange}

  getClients:(socketId)-> @clients[socketId]

  joinBongoClient:(messageData, routingKey, socketId)->
    @authenticate messageData, routingKey, (session)->
      {exchange} = @bongo.mq
      exchange.publish 'auth.join', {
        username    : session.username
        routingKey  : routingKey
      }
      @addClient socketId, exchange.name, routingKey

  joinKiteClient:(messageData, routingKey, socketId)->
    {channel} = messageData
    console.log {channel}
    @authenticate messageData, routingKey, (session)=>
      console.log session
      serviceName = @getNextServiceName channel
      unless serviceName
        @rejectClient routingKey
      else
        @bongo.mq.connection.exchange serviceName, (exchange)=>
          exchange.publish 'auth.join', {
            username    : session.username
            routingKey  : routingKey
          }
          exchange.close() # don't leak a channel
          @addClient socketId, exchange.name, routingKey

  # TODO: authenticate the kite client

  rejectClient:(routingKey, message)->
    console.log 'rejecting client', arguments
    @bongo.respondToClient routingKey, {error: message ? 'Access denied'}

  joinClient:(data, socketId)->
    {channel, routingKey, serviceType} = data
    switch serviceType
      when 'bongo' then @joinBongoClient data, routingKey, socketId
      when 'kite'  then @joinKiteClient data, routingKey, socketId
      else              @rejectClient routingKey

  cleanUpClient:(client)->
    console.log 'got a client'
    @bongo.mq.connection.exchange client.exchange, (exchange)->
      exchange.publish 'auth.leave', {
        routingKey: client.routingKey
      }

  cleanUpAfterDisconnect:(socketId)->
    console.log 'd/c', socketId, this
    @getClients(socketId)?.forEach @bound 'cleanUpClient'

    # TODO: implement cleanup

  authExchangeOptions = {type: 'fanout', autoDelete: yes}

  connect:->
    {bongo} = this
    bongo.mq.ready =>
      {connection} = bongo.mq
      connection.exchange @resourceName, authExchangeOptions, (authExchange)=>
        connection.queue  @resourceName, (authQueue)=>
          authQueue.bind authExchange, ''
          authQueue.on 'queueBindOk', =>
            authQueue.subscribe (message, headers, deliveryInfo)=>
              console.log {deliveryInfo}
              {routingKey, correlationId} = deliveryInfo
              socketId = correlationId
              messageStr = "#{message.data}"
              messageData = try JSON.parse messageStr
              switch routingKey
                when 'broker.clientConnected' then # ignore
                when 'broker.clientDisconnected'
                  @cleanUpAfterDisconnect messageStr
                when 'kite.join'
                  @addService messageData
                when 'kite.leave'
                  @addService messageData
                when 'client.auth'
                  @joinClient messageData, socketId
                when 'client.killAuth' then process.kill()
                else
                  @rejectClient routingKey
