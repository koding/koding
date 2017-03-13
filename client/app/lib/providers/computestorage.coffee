debug = (require 'debug') 'cs'

kd = require 'kd'
Encoder = require 'htmlencode'

remote  = require('../remote')
globals = require 'globals'

isGroupDisabled = require 'app/util/isGroupDisabled'


module.exports = class ComputeStorage extends kd.Object


  Storage        =
    machine      :
      path       : 'machines'
      collection : 'JMachine'
      payload    : 'userMachines'
      modifier   : (machines) ->
        machines = [ machines ]  unless Array.isArray machines
        machines.map (machine) ->
          return remote.revive machine

    stack        :
      path       : 'stacks'
      collection : 'JComputeStack'
      payload    : 'userStacks'
      modifier   : (stacks) ->
        stacks = [ stacks ]  unless Array.isArray stacks
        stacks.map (stack) =>
          stack = remote.revive stack
          stack.title = Encoder.htmlDecode stack.title
          stack.machines = stack.machines
            .map    (machineId) => @get 'machines', '_id', machineId
            .filter (machine)   -> machine.bongo_?
          return stack

    template     :
      path       : 'templates'
      collection : 'JStackTemplate'

    credential   :
      path       : 'credentials'
      collection : 'JCredential'


  constructor: ->
    super

    do @initialize


  initialize: ->

    disabled = isGroupDisabled()

    @storage = new Object
    Object.keys(Storage).forEach (type) =>

      { path } = Storage[type]
      if not disabled and payload = Storage[type].payload
        payloadData = globals[payload]
        @storage[path] = Storage[type].modifier?.call this, payloadData
      else
        @storage[path] = []

    debug 'storage initialized as', @storage

    return this


  set: (type, data) ->

    console.warn '[Warning] ComputeStorage::set will be deprecated!'

    debug 'set', type, data

    return this  if isGroupDisabled()

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

    debug 'push', options

    return  if isGroupDisabled()

    { machine, stack, template, machineId } = options

    if template
      @storage.templates.push template


  pop: (options = {}) ->

    { machine, stack, template, machineId } = options

    debug 'pop', options


  fetch: ->

    debug 'fetch'

    kd.warn 'wip'
