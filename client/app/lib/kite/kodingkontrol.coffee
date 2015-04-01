SockJS = require 'sockjs-client'
kitejs = require 'kite.js'
Promise = require 'bluebird'
kookies = require 'kookies'
kd = require 'kd'
KDNotificationView = kd.NotificationView
globals = require 'globals'
splitKiteQuery = require '../util/splitKiteQuery'
KiteCache = require './kitecache'
KiteLogger = require '../kitelogger'
KodingKite = require './kodingkite'


module.exports = class KodingKontrol extends KontrolJS = (kitejs.Kontrol)

  constructor: (options = {})->

    @_kontrolUrl = options.kontrolUrl  if options.kontrolUrl?

    super @getAuthOptions()

    @kites   = {}
    @regions = {}


  authenticate: ->
    super

    @kite.on 'close', (reason)->
      kd.log "Kontrol disconnected because ", reason


  getAuthOptions: ->

    @_lastUsedKey = kookies.get 'clientId'

    autoConnect           : no
    autoReconnect         : yes
    url                   : @_kontrolUrl ? globals.config.newkontrol.url
    auth                  :
      type                : 'sessionID'
      key                 : @_lastUsedKey
    transportClass        : SockJS
    transportOptions      :
      heartbeatTimeout    : 30 * 1000 # 30 seconds
      # Force XHR for all kind of kite connection
      protocols_whitelist : ['xhr-polling'] # , 'xhr-streaming']


  renewToken: (kite, query) ->

    KiteCache.unset query

    if @kite?
      KontrolJS::renewToken.call this, kite, query

    else
      @reauthenticate()
      @once 'open', =>
        KontrolJS::renewToken.call this, kite, query


  reauthenticate: (initial)->

    if @_lastUsedKey?
      if (kookies.get 'clientId') isnt @_lastUsedKey
        # disconnect the old kontrol kite
        @kite?.disconnect()

    # reauthenticate with the current session token
    @authenticate @getAuthOptions()


  fetchKite: Promise.promisify (args, callback)->

    if (cachedKite = KiteCache.get args.query)?
      return callback null, @createKite cachedKite, args.query

    KontrolJS::fetchKite.call this, args, callback


  fetchKites: Promise.promisify (args, callback) ->

    {query} = args

    @queryKites args
      .then (result)=>
        if query? and result.kites.length > 0
          KiteCache.cache query, result.kites.first

        callback null, @createKites result.kites


  queryKites: Promise.promisify (args, callback) ->

    @reauthenticate()  unless @kite?
    args = @injectQueryParams args

    @kite.tell 'getKites', [args], (err, result) =>
      return callback err  if err?

      unless result?
        callback @createKiteNotFoundError args.query
        return

      callback null, result


  getVersion: (name) ->
    return globals.config.kites[name]?.version


  injectQueryParams: (args = {}) ->

    args.query             ?= {}
    if version = @getVersion args.query.name
      args.query.version   ?= version
    args.query.username    ?= globals.config.kites.kontrol.username

    return args


  getCachedKite: (name, correlationName) ->
    @kites[name]?[correlationName]


  setCachedKite: (name, correlationName, kite) ->
    @kites[name] ?= {}
    unless kite?
      delete @kites[name][correlationName]
    else
      @kites[name][correlationName] = kite


  getKiteProxy: (options) ->

    { name, correlationName } = options

    KodingKite.constructors.klient = require './kites/klient'
    KodingKite.constructors.kloud = require './kites/kloud'
    konstructor = KodingKite.constructors[name]
    kite = new konstructor options

    @setCachedKite name, correlationName, kite

    return kite


  createKite: (options, query)->

    {computeController} = kd.singletons

    {kite} = options
    kiteName = kite.name

    # If its trying to create a klient kite instance
    # allow to use websockets by emptying the protocols_whitelist
    if kiteName is 'klient'
      options.transportOptions = protocols_whitelist: []
    else if kiteName is 'kloud'
      options.autoReconnect = no

    kite = KontrolJS::createKite.call this, options

    if query?

      queryString = KiteCache.generateQueryString query

      kite.on 'close', (event)=>

        return  unless event?.code is 1002

        kite.options.autoReconnect = no
        KiteCache.unset query

        kiteInstance = @kites[kiteName]?['singleton'] or {}
        {waitingPromises} = kiteInstance

        delete @kites[kiteName]['singleton']

        if machine = computeController.findMachineFromQueryString queryString
          delete @kites[kiteName][machine.uid]

        @getKite { name: kiteName, queryString, waitingPromises }

    return kite


  followConnectionStates: (kite, machineUId)->

    # Machine.uid is kite correlation name
    cc = kd.singletons.computeController

    kite.on 'open',      cc.lazyBound 'emit', "connected-#{machineUId}"
    kite.on 'close',     cc.lazyBound 'emit', "disconnected-#{machineUId}"
    kite.on 'reconnect', cc.lazyBound 'emit', "reconnecting-#{machineUId}"


  getKite: (options = {}) ->

    # Get options
    { name, correlationName, region, transportOptions, waitingPromises
      username, environment, version, queryString } = options

    # If no `correlationName` is defined assume this kite instance
    # is a singleton kite instance and keep track of it with this keyword
    correlationName ?= "singleton"

    # If queryString provided try to split it first
    # and if successful, use it as query
    if queryString? and queryObject = splitKiteQuery queryString
      query    = queryObject
      { name } = queryObject  if query.name

    # Check for cached version of requested kite with correlationName
    return kite  if (kite = @getCachedKite name, correlationName)?

    # Get Kite Proxy, it will be created at this point
    # since its not cached before
    kite = @getKiteProxy { name, correlationName, transportOptions }

    @followConnectionStates kite, correlationName  if name is 'klient'

    if waitingPromises? and waitingPromises.length > 0

      kite.once 'open', ->
        for promise in waitingPromises
          [resolve, args] = promise
          resolve (
            kite.transport?.tell args...
              .then (res)->
                KiteLogger.success name, args.first
                return res
              .catch (err)->
                KiteLogger.failed name, args.first
                throw err
          )

    # Query kontrol
    @fetchKite
      query : query ? { name, region, username, version, environment }

    # Connect to kite
    .then(kite.bound 'setTransport')

    # Report error
    .catch (err)=>

      kd.warn "[KodingKontrol] ", err

      # Instead parsing message we need to define a code or different
      # name for `No kite found` error in kite.js ~ FIXME GG
      if err and err.name is "KiteError" and /^No kite found/.test err.message
        @setCachedKite name, correlationName
        kite.invalid = err


    return kite
