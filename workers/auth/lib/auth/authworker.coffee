{EventEmitter} = require 'microemitter'

module.exports = class AuthWorker extends EventEmitter

  AuthedClient = require './authedclient'

  AUTH_EXCHANGE_OPTIONS =
    type        : 'fanout'
    autoDelete  : yes

  constructor:(@bongo, @resourceName, @presenceExchange='services-presence')->
    @services = {}
    @clients  = {
      bySocketId    : {}
      byExchange    : {}
      byRoutingKey  : {}
    }
    @counts   = {}
    # @monitorServices()

  bound: require 'koding-bound'

  # monitorServices: do ->
  #   pingAll =(services)->
  #     # for own servicesOfType of services
  #     #   servicesOfType.forEach (service)->
  #     # TODO: implement pingA       
  #   monitorServicesHelper =->
  #     console.log {@services, @clients}
  #     pingAll @services
  #   monitorServices =->
  #     handler = monitorServicesHelper.bind this
  #     setInterval handler, 10000

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
    return  unless servicesOfType?.length
    serviceName = servicesOfType[count % servicesOfType.length]
    @counts[serviceType] += 1
    return serviceName

  addService:({serviceGenericName, serviceUniqueName})->
    servicesOfType = @services[serviceGenericName] ?= []
    servicesOfType.push serviceUniqueName

  removeService:({serviceGenericName, serviceUniqueName})->
    servicesOfType = @services[serviceGenericName] 
    index = servicesOfType.indexOf serviceUniqueName
    servicesOfType.splice index, 1
    clientsByExchange = @clients.byExchange[serviceUniqueName]
    clientsByExchange.forEach @bound 'cycleClient'

  cycleClient:(client)->
    {routingKey} = client
    @bongo.respondToClient routingKey, {
      method      : 'cycleChannel'
      arguments   : []
      callbacks   : {}
    }

  removeClient:(rest...)->
    if rest.length is 1
      [client] = rest
      return @removeClient client.socketId, client.exchange, client.routingKey
    [socketId, exchange, routingKey] = rest
    delete @clients.bySocketId[socketId]
    delete @clients.byExchange[exchange]
    delete @clients.byRoutingKey[routingKey]

  addClient:(socketId, exchange, routingKey)->
    clientsBySocketId   = @clients.bySocketId[socketId]     ?= []
    clientsByExchange   = @clients.byExchange[exchange]     ?= []
    clientsByRoutingKey = @clients.byRoutingKey[routingKey] ?= []
    client = new AuthedClient {routingKey, socketId, exchange}
    clientsBySocketId.push client
    clientsByRoutingKey.push client
    clientsByExchange.push client

  rejectClient:(routingKey, message)->
    @bongo.respondToClient routingKey, {
      method    : 'error'
      arguments : [message: message ? 'Access denied']
      callbacks : {}
    }

  joinClient: do ->

    joinClientHelper =(messageData, routingKey, socketId)->
      @authenticate messageData, routingKey, (session)=>
        serviceResourceName = @getNextServiceName messageData.name
        unless serviceResourceName?
          @bongo.respondToClient routingKey, {
            method    : 'error'
            arguments : [message: 'Service unavailable!', code:503]
            callbacks : {}
          }
        else
          {connection} = @bongo.mq
          connection.exchange serviceResourceName, AUTH_EXCHANGE_OPTIONS,
            (exchange)=>
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
    @removeClient client
    @bongo.mq.connection.exchange client.exchange, AUTH_EXCHANGE_OPTIONS,
      (exchange)->
        exchange.publish 'auth.leave', {
          routingKey: client.routingKey
        }
        exchange.close() # don't leak a channel!

  cleanUpAfterDisconnect:(socketId)->
    @clients.bySocketId[socketId]?.forEach @bound 'cleanUpClient'

  parseServiceKey =(serviceKey)->
    last = null
    serviceInfo = serviceKey.split('.').reduce (acc, edge, i)->
      unless i % 2 then last = edge
      else acc[last] = edge
      return acc
    , {}
    isValidKey  = serviceInfo.serviceGenericName? and
                  serviceInfo.serviceUniqueName?
    throw {
      message: 'Bad service key!'
      serviceKey
      serviceInfo
    }  unless isValidKey

    return serviceInfo

  monitorPresence:(connection)->
    Presence = require 'koding-rabbit-presence'
    @presence = new Presence {
      connection
      exchange  : @presenceExchange
      member    : @resourceName
    }
    @presence.on 'join', (serviceKey)=>
      try @addService parseServiceKey serviceKey
      catch e then console.error e
    @presence.on 'leave', (serviceKey)=>
      try @removeService parseServiceKey serviceKey
      catch e then console.error e
    @presence.listen()

  connect:->
    {bongo} = this
    bongo.mq.ready =>
      {connection} = bongo.mq
      @monitorPresence connection
      connection.exchange @resourceName, AUTH_EXCHANGE_OPTIONS, (authExchange)=>
        connection.queue  @resourceName, (authQueue)=>
          authQueue.bind authExchange, ''
          authQueue.on 'queueBindOk', =>
            authQueue.subscribe (message, headers, deliveryInfo)=>
              {routingKey, correlationId} = deliveryInfo
              socketId = correlationId
              messageStr = "#{message.data}"
              messageData = (try JSON.parse messageStr) or message
              switch routingKey
                when 'broker.clientConnected' then # ignore
                when 'broker.clientDisconnected'
                  @cleanUpAfterDisconnect messageStr
                when 'kite.join'
                  @addService messageData
                when 'kite.leave'
                  @removeService messageData
                when 'client.auth'
                  @joinClient messageData, socketId
                else
                  @rejectClient routingKey
