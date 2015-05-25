amqp   = require "amqp"
{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{mq }  = KONFIG

module.exports = amqp.createConnection mq, reconnect: no
