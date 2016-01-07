'use strict'

module.exports =
  afterInit: ->
    @on? 'updateInstance', (data)=> @updateInstances(data)

  on:(event, listener)->
    multiplex = @multiplexer.on event, listener
    @on_? event, multiplex if multiplex

  off:(event, listener)->
    listenerCount = @multiplexer.off event, listener
    if listenerCount is 0
      @off_ event, @multiplexer.events[event]
