debug = (require 'debug') 'cs'
globals = require 'globals'
kd = require 'kd'


module.exports = class ComputeStorage extends kd.Object


  constructor: ->
    super

    @initialize()


  initialize: ->

    @storage  = {}
    @stacks   = []
    @machines = []

    return this


  set: (type, data) ->

    debug 'set', type, data
    @storage[type] = data

    switch type
      when 'machines'
        globals.userMachines = data

    return this


  query: (type, key, value) ->

    debug 'query requested', type, key, value

    res = []
    if items = @storage[type]
      res.push item  for item in items when item and item[key] is value

    [ res ] = res  if (key is '_id') and res.length is 1

    debug 'query result', res

    return res


  get: (type) -> @storage[type] ? []


  push: (options = {}) ->

    { machine, stack, machineId } = options

    debug 'push', options


  pop: (options = {}) ->

    { machine, stack, machineId } = options

    debug 'pop', options
