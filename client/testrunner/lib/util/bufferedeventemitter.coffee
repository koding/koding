{ EventEmitter } = require 'events'

module.exports = class BufferedEventEmitter extends EventEmitter

  constructor: ->

    super

    @__eventQueue = []


  emit: (args...) ->

    @__eventQueue.push args


  emitAll: ->

    @__eventQueue.map (args) =>
      EventEmitter::emit.apply this args

    @__eventQueue = []


  toJSON: ->

    JSON.stringify @__eventQueue, (key, value) ->
      if value?._afterEach? and value?._slow?
        return undefined
      return value
