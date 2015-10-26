amqp     = require 'amqp'
{ argv } = require 'optimist'
KONFIG   = require('koding-config-manager').load("main.#{argv.c}")
{ mq }   = KONFIG

conn = amqp.createConnection mq, { reconnect: yes }
conn.on 'error', (err) ->
  console.error "Error: connecting to RabbitMQ", err
  process.exit(1)

module.exports = conn
