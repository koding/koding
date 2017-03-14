debug = (require 'debug') 'cs'

kd = require 'kd'
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
          return remote.revive machine

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

      postPush   : (stacks) ->
        { reactor } = kd.singletons
        reactor.dispatch actions.LOAD_USER_ENVIRONMENT_SUCCESS, @get 'machines'
        reactor.dispatch actions.LOAD_USER_STACKS_SUCCESS, @get 'stacks'

      modifier   : (stacks) ->
        stacks.map (stack) =>
          stack = remote.revive stack
          stack.title = Encoder.htmlDecode stack.title
          stack.machines = stack.machines
            .map (machine) =>
              if machine.bongo_
              then machine
              else @get 'machines', '_id', machine

            .filter (machine) ->
              machine?.bongo_?

          return stack

    templates    :
      collection : 'JStackTemplate'

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

    return this


  set: (type, data) ->

    console.warn 'ComputeStorage::set will be deprecated!'

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


  push: (type, value) ->

    debug 'push', type, value

    return  if isGroupDisabled()

    debug 'before push', @storage
    kd.utils.defer =>
      debug 'after push', @storage

    return  unless Storage[type]

    { modifier, prePush, postPush } = Storage[type]

    if cached = @get type, '_id', value._id ? value
      debug 'pushed data was in cache, passed'
      return cached

    if typeof value is 'string'
      return @fetch type, value

    [ value ] = modifier.call this, [ value ]  if modifier

    prePush?.call this, value

    @storage[type].push value

    postPush?.call this, value

    return value


  pop: (type, key, value) ->

    debug 'pop', type, key, value

    [ key, value ] = [ value, key ]  unless value
    key ?= '_id'

    debug 'before pop', @storage
    kd.utils.defer =>
      debug 'after pop', @storage

    return  unless Storage[type]
    { prePop, postPop } = Storage[type]

    value = value._id ? value

    prePop?.call this, value

    @storage[type] = @storage[type].filter (item) ->
      item._id isnt value

    postPop?.call this, value

    return value


  fetch: (type, key, value) ->

    debug 'fetch', type, key, value

    [ key, value ] = [ value, key ]  unless value
    key ?= '_id'

    new Promise (resolve, reject) =>

      unless @storage[type]
        return reject new Error 'Storage not supported'

      if isGroupDisabled()
        return reject new Error 'Team disabled'

      if cached = @get type, key, value
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
