amqp     = require 'amqp'
{ argv } = require 'optimist'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")
{ mq }   = KONFIG

bongo    = require './bongo'
conn     = amqp.createConnection mq, { reconnect: yes }

conn.on 'error', (err) ->

  console.error 'Error: connecting to RabbitMQ', err
  process.exit(1)


conn.on 'ready', ->

  { Tracker }  = bongo.models

  queueName    = 'NodeMailSender:0:WorkerQueue'
  queueOptions = { durable: yes, autoDelete: no }

  exchangeName = 'BrokerMessageBus:0'
  emailEvent   = 'api.mail_send'

  conn.queue queueName, queueOptions, (queue) ->
    queue.bind exchangeName, '#', ->

      queue.subscribe (message, header, property) ->

        return  unless property.type is emailEvent

        message = JSON.parse message.data.toString()

        if Tracker.isEmailEvent message.Subject
          console.log ">>>> SEND '#{message.Subject}' email to #{message.To}"

module.exports = conn
