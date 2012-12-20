{EventEmitter} = require 'microemitter'

module.exports = class AuthWorker extends EventEmitter

  AuthedClient = require './authedclient'

  authExchangeOptions = {type: 'fanout', autoDelete: yes}

  constructor:(@bongo, @resourceName, @presenceExchange='services-presence')->
    @services = {}
    @clients  = {}
    @counts   = {}
    @monitorServices()

  bound: require 'koding-bound'

  monitorServices: do ->
    pingAll =(services)->
      # for own servicesOfType of services
      #   servicesOfType.forEach (service)->
      # TODO: implement pingA       
    monitorServicesHelper =->
      console.log {@services}
      pingAll @services
    monitorServices =->
      handler = monitorServicesHelper.bind this
      setInterval handler, 10000

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
    return serviceType  unless servicesOfType?.length
    serviceName = servicesOfType[count % servicesOfType.length]
    @counts[serviceType] += 1
    return serviceName

  addService:({serviceGenericName, serviceUniqueName})->
    console.log 'addService', {serviceGenericName, serviceUniqueName}
    servicesOfType = @services[serviceGenericName] ?= []
    servicesOfType.push serviceUniqueName

  removeService:({serviceGenericName, serviceUniqueName})->
    console.log 'removeService', {serviceGenericName, serviceUniqueName}
    servicesOfType = @services[serviceGenericName]
    index = servicesOfType.indexOf serviceUniqueName
    servicesOfType.splice index, 1

  addClient:(socketId, exchange, routingKey)->
    clientsBySocketId = @clients[socketId]
    clientsBySocketId = @clients[socketId] = []  unless clientsBySocketId?
    clientsBySocketId.push new AuthedClient {routingKey, socketId, exchange}

  getClients:(socketId)-> @clients[socketId]

  rejectClient:(routingKey, message)->
    console.log 'rejecting client', arguments
    console.trace()
    @bongo.respondToClient routingKey, {error: message ? 'Access denied'}

  joinClient: do ->

    joinClientHelper =(messageData, routingKey, socketId)->
      @authenticate messageData, routingKey, (session)=>
        serviceResourceName = @getNextServiceName messageData.name
        console.log {orig: messageData.name, new: serviceResourceName}
        @bongo.mq.connection.exchange serviceResourceName, authExchangeOptions,
          (exchange)=>
            console.log {exchange}
            exchange.publish 'auth.join', {
              username    : session.username
              routingKey  : routingKey
            }
            exchange.close() # don't leak a channel
            @addClient socketId, exchange.name, routingKey

    joinClient =(messageData, socketId)->
      {channel, routingKey, serviceType} = messageData
      switch serviceType
        when 'bongo', 'kite'
          joinClientHelper.call this, messageData, routingKey, socketId
        else
          @rejectClient routingKey

  cleanUpClient:(client)->
    @bongo.mq.connection.exchange client.exchange, authExchangeOptions,
      (exchange)->
        exchange.publish 'auth.leave', {
          routingKey: client.routingKey
        }

  cleanUpAfterDisconnect:(socketId)->
    @getClients(socketId)?.forEach @bound 'cleanUpClient'
    delete @clients[socketId]

  parseServiceKey =(serviceKey)->
    last = null
    serviceInfo = serviceKey.split('.').reduce (acc, edge, i)->
      if i % 2 then last = edge
      else acc[last] = edge
      return acc
    , {}
    isValidKey  = serviceInfo.serviceGenericName? and
                  serviceInfo.serviceUniqueName?
    throw message: 'Bad service key!'  unless isValidKey
    return serviceInfo

  monitorPresence:(connection)->
    console.log 'monitorPresence'
    Presence = require 'koding-rabbit-presence'
    @presence = new Presence {
      connection
      exchange  : @presenceExchange
      member    : @resourceName
    }
    @presence.on 'join', (serviceKey)=>
      console.log serviceKey, 'joined'
      try @addService parseServiceKey serviceKey
    @presence.on 'leave', (serviceKey)=>
      console.log serviceKey, 'left'
      try @removeService parseServiceKey serviceKey
    @presence.listen()

  connect:->
    {bongo} = this
    bongo.mq.ready =>
      {connection} = bongo.mq
      @monitorPresence connection
      connection.exchange @resourceName, authExchangeOptions, (authExchange)=>
        connection.queue  @resourceName, (authQueue)=>
          authQueue.bind authExchange, ''
          authQueue.on 'queueBindOk', =>
            authQueue.subscribe (message, headers, deliveryInfo)=>
              {routingKey, correlationId} = deliveryInfo
              socketId = correlationId
              messageStr = "#{message.data}"
              messageData = (try JSON.parse messageStr) or message
              console.log 'routingKey', routingKey
              switch routingKey
                when 'broker.clientConnected' then # ignore
                when 'broker.clientDisconnected'
                  @cleanUpAfterDisconnect messageStr
                when 'kite.join'
                  @addService messageData
                when 'kite.leave'
                  @removeService messageData
                when 'client.auth'
                  console.log 'in the client auth codepath'
                  @joinClient messageData, socketId
                when 'client.killAuth' then process.kill()
                else
                  console.log 'rejecting client', message, headers, deliveryInfo, ''+message.data
                  @rejectClient routingKey
