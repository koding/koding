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

    @_connection = amqp.createConnection KONFIG.mq, { reconnect: yes }

    @_connection.on 'error', (err) =>
      @log 'Error: connecting to RabbitMQ', err

    @_connection.on 'ready', =>
      @log 'started successfully'
      @_assertExchange()

    @_connectToBongo()

    @_createSocketServer()
    @_createExpressApp()
    @_startServer()


  sendNotification: (notification) ->

    unless @isReady()
      @_queue.push notification
      return

    @_exchange.publish '', JSON.stringify { message: notification }


  log: (message...) ->

    console.log "[NW][#{argv.i ? 0}]", message...


  isReady: ->

    return @_state is READY and @_bongo


  _setReady: ->

    @_state = READY

    @_socket.on 'connection', @_handleSocketConnection.bind this
    @sendNotification notification  for notification in @_queue

    return READY


  _connectToBongo: ->

    bongo.once 'apiReady', =>
      @log 'bongo connected.'
      @_bongo = bongo


  _createSocketServer: ->

    @_socket = sockjs.createServer()

    return @_socket


  _createExpressApp: ->

    @_app = express()

    @_app.use bodyParser.json { limit: '100kb' }
    @_app.use helmet()
    @_app.use cors()

    @_app.get '/notify', (req, res) =>
      res.send """
        <pre>
          NotificationWorker #{argv.i ? 0} is #{if @isReady() then '' else 'not '}ready
          Connections: #{JSON.stringify @_verifiedConnections}
          Routes: #{JSON.stringify @_verifiedRoutes}
        </pre>
      """

    @_app.post '/notify/send', @_handleSendNotification.bind this


  _startServer: ->

    @_server = http.createServer @_app
    @_socket.installHandlers @_server, { prefix: '/notify/subscribe' }
    @_server.listen argv.p


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
      queue.subscribe @_handleNewMessage.bind this


  _handleNewMessage: (message, header, property) ->

    [ err, parsedMessage ] = @_parseMessage message.data.toString()

    if err
      @log 'failed to parse message', err
      @log 'message was', message

    else
      @log 'got message', parsedMessage
      for id of @_verifiedConnections
        @_connections[id].write parsedMessage.message


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
    @_proccessMessage connection, message


  _handleSendNotification: (req, res) ->

    @log 'got hit on send'
    res.send 'NotificationWorker is OK'


  _parseMessage: (message) ->

    try
      message = JSON.parse message
    catch error
      return [ { error, message: 'Not a valid JSON' } ]

    return [ null, message ]


  _proccessMessage: (connection, message) ->

    if connection.id not in @_verifiedConnections

      @log 'connection not verified, checking...'
      [ err, parsedMessage ] = @_parseMessage message

      if err or not parsedMessage?.auth?
        @_dropConnection connection

      else
        { clientId, username, groupName } = parsedMessage.auth

        if /^guest-/.test username
          return @_dropConnection connection

        @_bongo.models.JSession.one { clientId, username, groupName }, (err, session) =>
          if err or not session
            @_dropConnection connection
          else
            @_verifyConnection connection, "#{groupName}:#{username}"
            connection.write 'welcome'

    else
      connection.write 'ok'


  _verifyConnection: (connection, route) ->

    @_verifiedConnections.push connection.id
    @_verifiedRoutes.push "#{route}:#{connection.id}"
    @log 'connection verified now, welcome!', connection.url

    return connection


  _dropConnection: (connection) ->

    connection.close()
    return  unless @_connections[connection.id]

    @_verifiedConnections = @_verifiedConnections.filter (connectionId) ->
      connection.id isnt connectionId

    @_verifiedRoutes = @_verifiedRoutes.filter (route) ->
      [group, username, connectionId] = route.split ':'
      connection.id isnt connectionId

    delete @_connections[connection.id]
    @log 'connection dropped. goodbye!', connection.url

    return null
