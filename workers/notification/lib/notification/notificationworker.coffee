cors = require 'cors'
http = require 'http'
amqp = require 'amqp'

sockjs = require 'sockjs'
helmet = require 'helmet'

express    = require 'express'
{ argv }   = require 'optimist'
bodyParser = require 'body-parser'

KONFIG = require 'koding-config-manager'
bongo  = require '../../../../servers/lib/server/bongo'

module.exports = class NotificationWorker


  QUEUEPREFIX  = 'NodeNotification'
  QUEUEOPTIONS = { durable: yes, autoDelete: yes }

  EXCHANGENAME = 'NotificationMessageBus:0'
  EXCHANGE_OPTIONS = {
    autoDelete: yes
    durable: yes
    type: 'fanout'
  }

  [ NOTREADY, READY ] = [ 0, 1 ]


  constructor: ->

    @_state = NOTREADY
    @_queue = []

    @_queueName = "#{QUEUEPREFIX}:#{Math.random().toString().slice(2, 10)}"

    @_connections = {}
    @_verifiedConnections = []
    @_verifiedRoutes = []


  start: ->

    @log 'starting worker...'

    @_connectToBongo =>

      @_connectToRabbitMQ()
      @_createSocketServer()
      @_createExpressApp()

      @_startServer()


  # notification sender which publishes a message over exchange to all
  # queue consumers with provided routingKey which can be;
  #
  #   - groupName:username  -- for user notifications
  #   - groupName           -- for group notifications
  #
  sendNotification: (routingKey, notification) ->

    @log 'got request to send notification to', routingKey

    unless routingKey
      return @log 'routingKey not specified, dropping to floor.'

    unless @isReady()
      @log 'worker is not ready yet, pushed to queue'
      @_queue.push [ routingKey, notification ]
      return

    @_exchange.publish routingKey, JSON.stringify notification


  # internal logger
  log: (message...) ->

    console.log "[NW][#{argv.i ? 0}]", message...


  # returns true if exchange is ready and bongo connected
  isReady: ->

    return @_state is READY and @_bongo


  # --- internals

  _setReady: ->

    @_state = READY

    @_socket.on 'connection', @_handleSocketConnection.bind this

    for notification in @_queue
      @sendNotification notification...

    @_queue = []

    return READY


  _connectToBongo: (callback) ->

    bongo.once 'apiReady', =>
      @log 'bongo connected.'
      @_bongo = bongo

      callback null


  _connectToRabbitMQ: ->

    @_connection = amqp.createConnection KONFIG.mq, { reconnect: yes }

    @_connection.on 'error', (err) =>
      @log 'Error: connecting to RabbitMQ', err

    @_connection.on 'ready', =>
      @log 'started successfully'
      @_assertExchange()


  _createSocketServer: ->

    @_socket = sockjs.createServer()

    return @_socket


  _createExpressApp: ->

    @_app = express()

    @_app.use bodyParser.json { limit: '100kb' }
    @_app.use helmet()
    @_app.use cors()

    @_app.get  '/notify',                  @_handleStatusRequest.bind this
    @_app.post '/dispatcher_notify_user',  @_handleSendNotification 'user'
    @_app.post '/dispatcher_notify_group', @_handleSendNotification 'group'

    return @_app


  _startServer: ->

    @_server = http.createServer @_app
    @_socket.installHandlers @_server, { prefix: '/notify/subscribe' }
    @_server.listen argv.p

    return @_server


  # --- mq helpers

  _assertExchange: ->

    @_exchange = @_connection.exchange EXCHANGENAME, EXCHANGE_OPTIONS
    @_exchange.on 'open', =>
      @log 'exchange verified', EXCHANGENAME
      @_assertQueue()
      @_setReady()


  _assertQueue: ->

    @_connection.queue @_queueName, QUEUEOPTIONS, (queue) =>
      @log 'queue verified', @_queueName
      @_bindExchange queue


  _bindExchange: (queue) ->

    unless queue
      return @log 'queue not provided'

    queue.bind EXCHANGENAME, '#', =>
      @log 'bounded to exchange', EXCHANGENAME
      queue.subscribe @_handleMqMessage.bind this


  # --- mq handlers

  _handleMqMessage: (message, header, property) ->

    [ err, parsedMessage ] = @_parseMessage message.data.toString()
    return @log 'got message but failed to parse', message  if err

    @log 'got message for', property.routingKey, parsedMessage

    [ t_group, t_user ] = property.routingKey.split ':'

    messageToSend = parsedMessage
    messageToSend.__to = { user: t_user, group: t_group }
    messageToSend = JSON.stringify messageToSend

    for route in @_verifiedRoutes
      [ group, user, id ] = route
      if group is t_group
        return  if t_user? and t_user isnt user
        @_connections[id]?.write messageToSend


  # --- express app handlers for internal use

  _handleSendNotification: (scope) -> (req, res) =>

    @log "got hit on send -- #{scope}", req.body

    { groupName, account, body } = req.body

    if scope is 'group'
      if groupName
        routingKey = groupName
      else
        return res.sendStatus 500

    else if scope is 'user'
      if (groupName = body?.context) and (username = account?.nick)
        routingKey = "#{groupName}:#{username}"
      else
        return res.sendStatus 500

    @sendNotification routingKey, body

    res.sendStatus 200


  _handleStatusRequest: (req, res) ->

    res.send """
      <pre>
        NotificationWorker #{argv.i ? 0} is #{if @isReady() then '' else 'not '}ready
        Connections: #{JSON.stringify @_verifiedConnections}
        Routes: #{JSON.stringify @_verifiedRoutes}
      </pre>
    """


  # --- socket handlers

  _handleSocketConnection: (connection) ->

    unless connection
      return @log 'connection is not valid'

    @log 'got new connection', connection.url

    @_connections[connection.id] = connection

    connection.on 'data', (message) =>
      @_handleSocketMessage connection, message

    connection.on 'close', =>
      @_dropConnection connection


  _handleSocketMessage: (connection, message) ->

    @log 'got socket message', message
    @_proccessSocketMessage connection, message


  _proccessSocketMessage: (connection, message) ->

    if connection.id not in @_verifiedConnections

      @log 'connection not verified, checking...'
      [ err, parsedMessage ] = @_parseMessage message

      if err or not parsedMessage?.auth?
        @_dropConnection connection

      else

        { clientId } = parsedMessage.auth

        @_bongo.models.JSession.one { clientId }, (err, session) =>
          if err or not session
            @_dropConnection connection

          else

            if /^guest-/.test session.username
              return @_dropConnection connection

            @_verifyConnection connection, session.groupName, session.username
            @_ackConnection connection

    else

      @_ackConnection connection


  _ackConnection: (connection) ->

    connection.write '{ "auth": "ok" }'


  # --- socker connection management

  _verifyConnection: (connection, group, user) ->

    @_verifiedConnections.push connection.id
    @_verifiedRoutes.push [ group, user, connection.id ]
    @log 'connection verified now, welcome!', connection.url

    return connection


  _dropConnection: (connection) ->

    connection.close()
    return  unless @_connections[connection.id]

    @_verifiedConnections = @_verifiedConnections.filter (connectionId) ->
      connection.id isnt connectionId

    @_verifiedRoutes = @_verifiedRoutes.filter (route) ->
      [ ... , connectionId ] = route
      connection.id isnt connectionId

    delete @_connections[connection.id]
    @log 'connection dropped. goodbye!', connection.url

    return null


  # --- generic parser for stringified json

  _parseMessage: (message) ->

    try
      message = JSON.parse message
    catch error
      return [ { error, message: 'Not a valid JSON' } ]

    return [ null, message ]
