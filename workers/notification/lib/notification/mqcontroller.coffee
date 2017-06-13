amqp = require 'amqp'
KONFIG = require 'koding-config-manager'


module.exports = class MQController

  QUEUEPREFIX  = 'NodeNotification'
  QUEUEOPTIONS = { durable: yes, autoDelete: yes }

  EXCHANGENAME = 'NotificationMessageBus:0'
  EXCHANGE_OPTIONS = {
    autoDelete: yes
    durable: yes
    type: 'fanout'
  }


  constructor: (options = {}) ->

    { @delegate, @messageHandler, @queueName } = options

    @log = @delegate.log.bind @delegate

    @_connection = amqp.createConnection KONFIG.mq, { reconnect: yes }

    @_connection.on 'error', (err) =>
      @log 'Error: connecting to RabbitMQ', err

    @_connection.on 'ready', =>
      @log 'started successfully'
      @_assertExchange()


  getExchange: -> @_exchange


  getConnection: -> @_connection


  _assertExchange: ->

    @_exchange = @_connection.exchange EXCHANGENAME, EXCHANGE_OPTIONS
    @_exchange.on 'open', =>
      @log 'exchange verified', EXCHANGENAME
      @_assertQueue()
      @delegate._setReady()


  _assertQueue: ->

    queueName = "#{QUEUEPREFIX}:#{@queueName}"
    @_connection.queue queueName, QUEUEOPTIONS, (queue) =>
      @log 'queue verified', queueName
      @_bindExchange queue


  _bindExchange: (queue) ->

    unless queue
      return @log 'queue not provided'

    queue.bind EXCHANGENAME, '#', =>
      @log 'bounded to exchange', EXCHANGENAME
      queue.subscribe @messageHandler.bind @delegate
