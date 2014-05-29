jraphical = require 'jraphical'

JTag   = require './models/tag'
amqp   = require 'amqp'
{argv} = require 'optimist'

KONFIG = require('koding-config-manager').load("main.#{argv.c}")

USER_EXCHANGE_OPTIONS =
  type       : 'fanout'
  autoDelete : no
  durable    : yes

tagModifierMQ = amqp.createConnection KONFIG.mq

tagModifierMQ.on 'ready', ->

  emitter = (tag, status) ->
    tagModifierMQ.exchange 'topicModifierExchange', USER_EXCHANGE_OPTIONS, (exchange) ->
      tagId = tag.getId()
      exchange.publish 'modifyTag', {tagId, status}
      exchange.close()

  JTag.on 'TagIsDeleted', (tag) ->
    emitter tag, 'delete'

  JTag.on 'TagIsSynonym', (tag) ->
    emitter tag, 'merge'




