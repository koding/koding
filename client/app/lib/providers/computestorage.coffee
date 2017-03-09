debug = (require 'debug') 'cs'

kd = require 'kd'
Encoder = require 'htmlencode'

remote  = require('../remote')
globals = require 'globals'
Machine = require './machine'


module.exports = class ComputeStorage extends kd.Object


  constructor: ->
    super

    @initialize()


  initialize: ->

    @storage = {}

    { userMachines, userStacks } = globals

    machines = []
    for machine in userMachines
      machines.push new Machine { machine: remote.revive machine }

    @set 'machines', machines

    stacks = []
    userStacks.forEach (stack) =>
      stack = remote.revive stack
      stack.title = Encoder.htmlDecode stack.title
      stack.machines = stack.machines
        .filter (mId) => @query 'machines', '_id', mId
        .map    (mId) => @query 'machines', '_id', mId
      stacks.push stack

    @set 'stacks', stacks

    return this


  set: (type, data) ->

    debug 'set', type, data
    @storage[type] = data

    return this


  query: (type, key, value) ->

    debug 'query requested', type, key, value

    res = []
    if items = @storage[type]
      res.push item  for item in items when item and item[key] is value

    [ res ] = res  if (key is '_id') and res.length is 1

    debug 'query result', res

    return res


  get: (type, key, value) ->

    if not key and not value
      return @storage[type] ? []

    [ item ] = @query type, key, value
    return item


  push: (options = {}) ->

    { machine, stack, machineId } = options

    debug 'push', options


  pop: (options = {}) ->

    { machine, stack, machineId } = options

    debug 'pop', options


  fetch: ->

    debug 'fetch'

    kd.warn 'wip'
