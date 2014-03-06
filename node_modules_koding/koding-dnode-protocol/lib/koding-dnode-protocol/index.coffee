{EventEmitter} = require 'events'
{getAt, setAt} = require 'jspath'
Scrubber = require 'scrubber'
createId = require('hat').rack()
stream = if process.title is "browser" then {} else require "stream"
json = `JSON` ? require 'jsonify'

exports = module.exports = (wrapper)->
  {
    sessions: {}

    create:->
      id = createId()
      @sessions[id] = new DnodeSession(id, wrapper)

    destroy:(id)-> delete @sessions[id]
  }

###*
* @class DnodeSession
* @description an implementation of the Session class from dnode-protocol
###
exports.Session = class DnodeSession extends EventEmitter
  constructor:(@id, wrapper)->

    @remote = {}

    @instance =\
      if 'function' is typeof wrapper then new wrapper(@remote, @)
      else wrapper or {}

    @localStore = new DnodeStore
    @remoteStore = new DnodeStore

    @localStore.on 'cull', (id)=>
      @emit 'request',
        method    : 'cull'
        arguments : [id]
        callbacks : {}

  start:-> @request 'methods', [@instance]

  request:(method, args)->
    scrubber = new DnodeScrubber @localStore
    scrubber.scrub args, =>
      scrubbed = scrubber.toDnodeProtocol()
      scrubbed.method = method
      @emit 'request', scrubbed

  parse:(line)=>
    try msg = json.parse line
    catch err then @emit 'error', new SyntaxError(
      "JSON parsing error: #{err}"
    )
    @handle msg


  handle:(msg)->
    scrubber = new DnodeScrubber @localStore
    args = scrubber.unscrub msg, (callbackId) =>
      unless @remoteStore.has callbackId
        @remoteStore.add callbackId, =>
          @request callbackId, [].slice.call arguments
      @remoteStore.get callbackId
    {method} = msg
    switch method
      when 'methods'
        @handleMethods args[0]
      when 'error'
        @emit 'remoteError', args[0]
      when 'cull'
        args.forEach (id)=> @remoteStore.cull id
      else
        switch typeof method
          when 'string'
            if @instance.propertyIsEnumerable method
              apply @instance[method], @instance, args
            else
              @emit 'error', new Error(
                "Request for non-enumerable method: #{method}"
              )
          when 'number'
            apply @localStore.get(method), @instance, args

  handleMethods:(methods)->
    methods ?= {}
    Object.keys(@remote).forEach (key)=> delete @remote[key]
    Object.keys(methods).forEach (key)=> @remote[key] = methods[key]
    @emit 'remote', @remote
    @emit 'ready'

  apply =(fn, ctx, args)-> fn.apply ctx, args
###*
* @class DnodeScrubber
* @description an implementation of the Scrubber class from dnode-protocol that supports a middleware stack
###
exports.Scrubber = class DnodeScrubber extends Scrubber
  constructor:(store=new DnodeStore, stack, autoCull = yes)->
    @paths = {}
    @links = []
    dnodeMutators = [
      # scrub function refs
      (cursor)->
        {node, path} = cursor
        if 'function' is typeof node
          i = store.indexOf node
          if ~i and !(i of @paths)
            @paths[i] = path
          else
            node.times = 1  if autoCull
            id = store.add node
            @paths[id] = path
          cursor.update '[Function]', yes
      # scrub circular refs
      # (cursor)->
      #   if cursor.circular
      #     @links.push
      #       from  : cursor.circular.path
      #       to    : cursor.path
      #     cursor.update '[Circular]', yes
    ]
    userStack = stack ? DnodeScrubber.stack ? []
    Scrubber.apply @, dnodeMutators.concat userStack

  unscrub:(msg, getCallback)->
    args = msg.arguments or []
    Object.keys(msg.callbacks or {}).forEach (strId)->
      id = parseInt strId, 10
      path = msg.callbacks[id]
      callback = getCallback id
      callback.id = id
      setAt args, path, callback
    (msg.links or []).forEach (link)->
      setAt(args, link.to, getAt(args, link.from))
    args

  toDnodeProtocol:->
    out = arguments : @out
    out.callbacks = @paths
    out.links = @links if @links.length
    out

###*
* @class DnodeStore
* @description an implementation of the Store class from dnode-protocol
###
exports.Store = class DnodeStore extends EventEmitter
  constructor: ->
    @items = []

  has: (id) -> @items[id]?

  get: (id) ->
    item = @items[id]
    return null unless item?
    @wrap item

  add: (id, fn) ->
    [fn, id] = [id, fn] unless fn
    id ?= @items.length
    @items[id] = fn
    id

  cull: (arg) ->
    arg = @items.indexOf(arg) if 'function' is typeof arg
    delete @items[arg]
    arg

  indexOf:(fn) ->
    @items.indexOf fn

  wrap: (fn) -> =>
    fn.apply this, arguments
    @autoCull fn

  autoCull: (fn) ->
    if 'number' is typeof fn.times
      fn.times--
      if fn.times is 0
        id = @cull fn
        @emit 'cull', id

parseArgs = exports.parseArgs = (argv) ->
  params = {}
  [].slice.call(argv).forEach (arg) ->
    switch typeof arg
      when 'string'
        if arg.match /^\d+$/
          params.port = parseInt arg, 10
        else if arg.match "^/"
          params.path = arg
        else
          params.host = arg
      when 'number'
        params.port = arg
      when 'function'
        params.block = arg
      when 'object'
        if arg.__proto__ is Object::
          Object.keys(arg).forEach (key) -> params[key] = arg[key]
        else if stream.Stream and arg instanceof stream.Stream
          params.stream = arg
        else
          params.server = arg
      when 'undefined' then break
      else throw new Error 'Not sure what to do about ' + typeof arg + ' objects'
  params