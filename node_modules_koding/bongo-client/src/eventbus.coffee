'use strict'

module.exports = class EventBus

  ListenerTree = require './listenertree'

  constructor:(@mq)->
    @tree = new ListenerTree
    @channels = {}
    @counts = {}

  bound: require 'koding-bound'

  dispatch:(routingKey, payload)->
    @tree.emit routingKey, payload

  addListener:(getGenericRoutingKey, getRoutingKey, name, event, listener)->
    unless @channels[name]?
      @counts[name] = 0
      genericRoutingKey = getGenericRoutingKey name
      channel = @channels[name] = @mq.subscribe genericRoutingKey,
        isReadOnly        : yes
        mustAuthenticate  : no
    else
      channel = @channels[name]
    unless channel.isListeningTo event
      channel.on event, @dispatch.bind this, getRoutingKey name, event
    @counts[name]++
    @tree.on (getRoutingKey name, event), listener

  removeListener:(getRoutingKey, name, event, listener)->
    if 0 is --@counts[name]
      channel = @channels[name]
      channel.close()
      delete @channels[name]
    @tree.off (getRoutingKey name, event), listener

  # static events:

  getStaticRoutingKey =(constructorName, event)->
    "constructor.#{constructorName}.event.#{event}"

  getGenericStaticRoutingKey =(constructorName)->
    "constructor.#{constructorName}.event"

  staticOn:(konstructor, event, listener)->
    @addListener(
      getGenericStaticRoutingKey, getStaticRoutingKey
      konstructor.name, event, listener
    )

  staticOff:(konstructor, event, listener)->
    @removeListener(
      getStaticRoutingKey
      konstructor.name, event, listener
    )

  # instance events:

  getInstanceRoutingKey =(oid, event)->
    "oid.#{oid}.event.#{event}"

  getGenericInstanceRoutingKey =(oid)->
    "oid.#{oid}.event"

  on:(inst, event, listener)->
    if inst.getSubscribable()
      @addListener(
        getGenericInstanceRoutingKey, getInstanceRoutingKey
        inst.getToken(), event, listener
      )

  off:(inst, event, listener)->
    @removeListener(
      getInstanceRoutingKey
      inst.getToken(), event, listener
    )
