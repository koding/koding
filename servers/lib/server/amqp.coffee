amqp     = require 'amqp'
{ mq }   = require 'koding-config-manager'

bongo    = require './bongo'
conn     = amqp.createConnection mq, { reconnect: yes }

conn.on 'error', (err) ->

  console.error 'Error: connecting to RabbitMQ', err
  process.exit(1)

module.exports = conn
