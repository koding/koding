'use strict'

module.exports = do->
  getPusherEvent =(event)->
    if Array.isArray(event)
      event = event.join ':'
    else event

  {defineProperty} = Object

  # afterInit:do ->
  #   channels = {}
  #   ->
  #     {broadcastable} = @constructor
  #     id = @getId?() or @bongo_?.instanceId
  #     if broadcastable and id?
  #       name = "object-#{id}"
  #       defineProperty @, "channel"
  #         get:=> channels[name] or= @mq.subscribe name
  #       @updateInstanceChannel.on name, (data)=>
  #         @update_(data.update) if data.update

  destroy:->
    return unless @channel?
    @mq.unsubscribe @channel
    # {constructor} = @
    # multiplex = @multiplexer.on event, (data)->
    #   payload = data?[event]
    #   if payload?
    #     constructor.wrapArgs [payload], ([arg])-> listener arg
    #   else if event is 'update'
    #     listener()

    # id = @getId?() or @bongo_?.instanceId
    # if id? and multiplex and event isnt 'update'
    #   name = "object-#{id}"
    #   @updateInstanceChannel.on name, multiplex

  removeListener:(event, listener)->
    @emit 'listenerRemoved', event, listener
    # @constructor.__super__.removeListener.call this, event, listener