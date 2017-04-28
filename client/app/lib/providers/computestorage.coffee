debug = (require 'debug') 'cs'

kd = require 'kd'
_ = require 'lodash'
Encoder = require 'htmlencode'
Promise = require 'bluebird'

remote  = require('../remote')
globals = require 'globals'

actions = require 'app/flux/environment/actiontypes'
isGroupDisabled = require 'app/util/isGroupDisabled'


module.exports = class ComputeStorage extends kd.Object


  Storage        =
    machines     :
      collection : 'JMachine'
      payload    : 'userMachines'
      modifier   : (machines) ->
        machines.map (machine) ->
          if machine.ಠ_ಠ then machine else remote.revive machine

    stacks       :
      collection : 'JComputeStack'
      payload    : 'userStacks'
      prePop     : (stackId) ->
        if cached = @get 'stacks', '_id', stackId
          @pop 'machines', '_id', machine._id  for machine in cached.machines

      postPop    : (stackId) ->
        { reactor } = kd.singletons
        reactor.dispatch actions.REMOVE_STACK, stackId

      prePush    : (stack) ->
        @push 'machines', machine  for machine in stack.machines

      postPush   : (stack) ->
        { reactor } = kd.singletons
        reactor.dispatch actions.LOAD_USER_ENVIRONMENT_SUCCESS, stack.machines
        reactor.dispatch actions.LOAD_USER_STACKS_SUCCESS, [ stack ]

      modifier   : (stacks) ->
        stacks.map (stack) =>
          stack = remote.revive stack  unless stack.ಠ_ಠ
          stack.title = Encoder.htmlDecode stack.title
          stack.machines = stack.machines
            .filter Boolean
            .map (machine) =>
              machine = if machine.bongo_
              then machine
              else @get 'machines', '_id', machine
              machine._stackId = stack._id  if machine
              return machine

            .filter (machine) ->
              machine?.bongo_?

          return stack

    templates    :
      collection : 'JStackTemplate'
      prePush    : (template) ->
        template.on 'update', kd.noop

    credentials  :
      collection : 'JCredential'


  constructor: ->
    super

    do @initialize


  initialize: ->

    disabled = isGroupDisabled()

    @storage = new Object
    Object.keys(Storage).forEach (type) =>

      if not disabled and payload = Storage[type].payload
        payloadData = globals[payload]
        @storage[type] = Storage[type].modifier?.call this, payloadData
      else
        @storage[type] = []

    debug 'storage initialized as', @storage

    do @createHelpers


  createHelpers: ->

    helpers = ['get', 'set', 'query', 'fetch', 'push', 'pop', 'update']

    (Object.keys Storage).forEach (store) =>
      this[store] = {}
      helpers.forEach (helper) =>
        this[store][helper] = (rest...) =>
          this[helper] store, rest...

    return this


  set: (type, data) ->

    console.warn 'ComputeStorage::set will be deprecated!'

    debug 'set', type, data

    return this  if isGroupDisabled()

    @storage[type] = data

    @emit 'change', { operation: 'set', type, data }
    @emit "change:#{type}", { operation: 'set', data }

    return this


  query: (type, key, value) ->

    debug 'query requested', type, key, value

    if items = @storage[type]

      [ key, value ] = [ value, key ]  unless value
      key ?= '_id'

      res = items
        .map (item) ->
          return item  if item and (item.getAt?(key) ? item[key]) is value
        .filter Boolean

    debug 'query result', res

    return res ? []


  get: (type, key, value) ->

    if not key and not value
      return @storage[type] ? []

    [ key, value ] = [ value, key ]  unless value
    key ?= '_id'

    if items = @storage[type]
      for item in items when (item and (item.getAt?(key) ? item[key]) is value)
        return item

    return null


  _deleteHandler: (type, value) ->
    => @pop type, value._id


  push: (type, value) ->

    debug 'push', type, value

    return  unless value
    return  if isGroupDisabled()

    debug 'before push', @storage
    kd.utils.defer =>
      debug 'after push', @storage

    return  unless Storage[type]

    { modifier, prePush, postPush } = Storage[type]

    if typeof value is 'string'
      return @fetch type, value

    [ value ] = modifier.call this, [ value ]  if modifier

    prePush?.call this, value

    if value?._id and cached = @update type, value._id, value
      debug 'pushed data was in cache, updated and passed'
      value = cached
    else
      @storage[type].push value
      value.off? 'deleteInstance', @_deleteHandler type, value
      value.on?  'deleteInstance', @_deleteHandler type, value

    postPush?.call this, value

    @emit 'change', { operation: 'push', type, value }
    @emit "change:#{type}", { operation: 'push', value }

    return value


  pop: (type, key, value) ->

    debug 'pop', type, key, value

    [ key, value ] = [ value, key ]  unless value
    key ?= '_id'

    debug 'before pop', @storage

    return  unless value
    return  unless Storage[type]
    { prePop, postPop } = Storage[type]

    value = value._id ? value

    prePop?.call this, value

    @storage[type] = @storage[type].filter (item) ->
      item[key] isnt value

    postPop?.call this, value

    @emit 'change', { operation: 'pop', type, value }
    @emit "change:#{type}", { operation: 'pop', value }

    debug 'after pop', @storage

    return value


  fetch: (type, key, value, reset = no) ->

    debug 'fetch', type, key, value

    [ key, value ] = [ value, key ]  unless value
    key ?= '_id'

    new Promise (resolve, reject) =>

      unless @storage[type]
        return reject new Error 'Storage not supported'

      if isGroupDisabled()
        return reject new Error 'Team disabled'

      if not reset and cached = @get type, key, value
        debug 'data found in cache'
        return resolve cached

      query = {}
      query[key] = value
      { collection } = Storage[type]

      debug 'fetching from remote', collection, query
      remote.api[collection].one query, (err, data) =>
        debug 'remote fetch result', err, data
        if err
          reject err
        else if data
          @push type, data
          resolve data
        else
          resolve null


  update: (type, key, value) ->

    debug 'update', type, key, value

    for item, index in (@get type)
      if item._id is key
        _.extend @storage[type][index], value
        return @storage[type][index]
