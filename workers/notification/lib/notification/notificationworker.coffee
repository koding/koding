KONFIG = require 'koding-config-manager'
bongo  = require '../../../../servers/lib/server/bongo'
sockjs = require 'sockjs'

MQController = require './mqcontroller'
ExpressController = require './expresscontroller'


module.exports = class NotificationWorker


  [ NOTREADY, READY ] = [ 0, 1 ]


  constructor: ->

    @_queueName = "#{Math.random().toString().slice(2, 10)}"

    @_state = NOTREADY
    @_queue = []

    @_connections = {}
    @_verifiedConnections = []
    @_verifiedRoutes = []


  start: ->

    @log 'starting worker...'

    @_connectToBongo =>

      @_createSocketServer()
      @_connectToRabbitMQ()
      @_createExpressApp()


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

    @_mq.getExchange().publish routingKey, JSON.stringify notification


  # internal logger
  log: (message...) ->

    console.log "[NW][#{@_queueName}]", message...


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


  _createSocketServer: ->

    @_socket = sockjs.createServer()

    return @_socket


  _connectToRabbitMQ: ->

    @_mq = new MQController {
      messageHandler: @_handleMqMessage
      queueName: @_queueName
      delegate: this
    }

    return @_mq


  _createExpressApp: ->

    @_express = new ExpressController {
      delegate: this
    }

    @_express.startServer @_socket

    return @_express


  # --- mq handlers

  _handleMqMessage: (message, header, property) ->

    [ err, parsedMessage ] = @_parseMessage message.data.toString()
    return @log 'got message but failed to parse', message  if err

    @log 'got message for', property.routingKey, parsedMessage

    [ t_group, t_user ] = property.routingKey.split ':'

    messageToSend = { content: parsedMessage }
    messageToSend.type = 'message'
    messageToSend.recipient = { user: t_user, group: t_group }

    messageToSend = JSON.stringify messageToSend

    for route in @_verifiedRoutes
      [ group, user, id ] = route
      if group is t_group
        return  if t_user? and t_user isnt user
        @_connections[id]?.write messageToSend


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

    connection.write '{ "type": "auth", "status": "ok" }'


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
