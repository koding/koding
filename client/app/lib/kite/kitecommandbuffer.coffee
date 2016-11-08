_ = require 'lodash'
kd = require 'kd'

debug = (type, args...) ->
  if _.isObject obj = args[0]
  then console[type] JSON.stringify obj, null, 2
  else console[type] args...


module.exports = class KiteCommandBuffer extends kd.Object

  constructor: (options = {}) ->

    # activating this will start logging to console.
    # use `commandBuffer.setOption('debug', yes)` to activate it on runtime.
    options.debug ?= no

    super options

    { kite } = options

    @kite = kite
    @storage = kd.utils.dict()

    @bindKiteEvents()


  debug: (args...) -> @getOption('debug') and debug args...


  bindKiteEvents: ->

    @kite.on 'tell', @bound 'onTellBegin'
    @kite.on 'tell.success', @bound 'onTellSuccess'
    @kite.on 'tell.fail', @bound 'onTellFail'


  onTellBegin: (id, method, args) ->

    @storage[id] = { method, args }
    @emit 'change'


  onTellSuccess: (id, method, result) ->

    @debug 'log', "~~~~~ SUCCESS (#{@kite.options.name}) ~~~~~"

    @storage[id] = _.assign {}, @storage[id], { result }
    @emit 'change'

    @debug 'log', @storage[id]


  onTellFail: (id, method, error) ->

    @debug 'error', '~~~~~ ERROR ~~~~~'

    @storage[id] = _.assign {}, @storage[id], { error }
    @emit 'change'

    @debug 'error', error

