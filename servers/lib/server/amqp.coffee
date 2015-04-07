amqp   = require "amqp"
{argv} = require 'optimist'
KONFIG = require('koding-config-manager').load("main.#{argv.c}")
{mq }  = KONFIG

mqConfig =
  host     : mq.host
  port     : mq.port
  login    : mq.login
  password : mq.password
  vhost    : mq.vhost

module.exports = amqp.createConnection mqConfig, reconnect: no
