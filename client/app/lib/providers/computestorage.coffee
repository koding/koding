debug = (require 'debug') 'cs'

kd = require 'kd'
Encoder = require 'htmlencode'

remote  = require('../remote')
globals = require 'globals'


module.exports = class ComputeStorage extends kd.Object


  constructor: ->
    super

    @initialize()


  initialize: ->

    @storage = {
      stacks    : []
      machines  : []
      templates : []
    }

    { userMachines, userStacks } = globals

    @set 'machines', userMachines.map (machine) ->
      return remote.revive machine

    @set 'stacks', userStacks.map (stack) =>
      stack = remote.revive stack
      stack.title = Encoder.htmlDecode stack.title
      stack.machines = stack.machines
        .filter (mId) => @get 'machines', '_id', mId
        .map    (mId) => @get 'machines', '_id', mId
      return stack

    return this


  set: (type, data) ->

    debug 'set', type, data
    @storage[type] = data

    return this


  query: (type, key, value) ->

    debug 'query requested', type, key, value

    if items = @storage[type]
      if typeof key is 'string'
        res = items
          .map (item) ->
            return item  if item and (item.getAt?(key) ? item[key]) is value
          .filter Boolean

    res ?= []

    debug 'query result', res

    return res


  get: (type, key, value) ->

    if not key and not value
      return @storage[type] ? []

    [ item ] = @query type, key, value
    return item


  push: (options = {}) ->

    { machine, stack, template, machineId } = options

    if template
      @storage.templates.push template

    debug 'push', options


  pop: (options = {}) ->

    { machine, stack, template, machineId } = options

    debug 'pop', options


  fetch: ->

    debug 'fetch'

    kd.warn 'wip'
