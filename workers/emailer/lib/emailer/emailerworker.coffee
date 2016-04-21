amqp     = require 'amqp'
{ argv } = require 'optimist'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")

Tracker  = require '../../../social/lib/social/models/tracker.coffee'


module.exports = class EmailerWorker

  MAILEVENTS = [
  # 'START_REGISTER'  # it's an email event but not required for basic emails ~ GG
    'REQUEST_NEW_PASSWORD'
    'CHANGED_PASSWORD'
    'REQUEST_EMAIL_CHANGE'
    'CHANGED_EMAIL'
    'INVITED_TEAM'
    'INVITED_CREATE_TEAM'
  ]

  getEmailType = (subject) ->
    return type  for type, val of Tracker.types when val is subject

  isEmailEvent = (subject) ->
    return (getEmailType subject) in MAILEVENTS

  ['log', 'error'].forEach (logger) ->
    EmailerWorker::[logger] = (message...) ->
      console[logger] '[EmailerWorker]', message...

  QUEUENAME    = 'NodeMailSender:0:WorkerQueue'
  QUEUEOPTIONS = { durable: yes, autoDelete: no }

  EXCHANGENAME = 'BrokerMessageBus:0'
  EMAILEVENT   = 'api.mail_send'


  start: ->

    @log 'starting...'

    @connection = amqp.createConnection KONFIG.mq, { reconnect: yes }

    @connection.on 'error', (err) =>
      @error 'Error: connecting to RabbitMQ', err

    @connection.on 'ready', =>
      @log 'started successfully'
      @createQueue()


  createQueue: ->

    @connection.queue QUEUENAME, QUEUEOPTIONS, (queue) =>

      @log 'queue created'

      queue.bind EXCHANGENAME, '#', =>
        queue.subscribe (message, header, property) =>

          return  unless property.type is EMAILEVENT

          message = JSON.parse message.data.toString()

          if isEmailEvent message.Subject
            @log "SEND '#{message.Subject}' [#{getEmailType message.Subject}] email to #{message.To}"
