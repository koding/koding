kd                 = require 'kd'

SockJS             = require 'sockjs-client'
globals            = require 'globals'
Promise            = require 'bluebird'
kookies            = require 'kookies'

kitejs             = require 'kite.js'
KiteCache          = require './kitecache'
KiteLogger         = require '../kitelogger'
KodingKite         = require './kodingkite'
splitKiteQuery     = require '../util/splitKiteQuery'


module.exports = class KodingKontrol extends KontrolJS = (kitejs.Kontrol)

  constructor: (options = {}) ->

    super @getAuthOptions()

    @kites   = {}
    @regions = {}


  authenticate: ->

    super

    @kite.on 'close', (reason) ->
      kd.log 'Kontrol disconnected because ', reason


  getLatestURL = -> "latest.#{globals.config.domains.base}"

  isLatest = ->
    location.hostname.indexOf(getLatestURL()) > -1

  @getKontrolUrl = ->

    if isLatest()
    then "https://#{getLatestURL()}/kontrol/kite"
    else globals.config.newkontrol.url


  getAuthOptions: ->

    @_lastUsedKey = kookies.get 'clientId'

    autoConnect           : no
    autoReconnect         : yes
    url                   : KodingKontrol.getKontrolUrl()
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


  reauthenticate: (initial) ->

    if @_lastUsedKey?
      if (kookies.get 'clientId') isnt @_lastUsedKey
        # disconnect the old kontrol kite
        @kite?.disconnect()

    # reauthenticate with the current session token
    @authenticate @getAuthOptions()


  fetchKite: Promise.promisify (args, callback) ->

    if (cachedKite = KiteCache.get args.query)?
      return callback null, @createKite cachedKite, args.query

    KontrolJS::fetchKite.call this, args, callback


  fetchKites: Promise.promisify (args, callback) ->

    { query } = args

    @queryKites args
      .then (result) =>

        if query? and result.kites.length > 0
          KiteCache.cache query, result.kites.first

        callback null, @createKites result.kites

        return result

    return null


  queryKites: Promise.promisify (args, callback) ->

    @reauthenticate()  unless @kite?
    args = @injectQueryParams args

    @kite.tell 'getKites', [args], (err, result) =>
      return callback err  if err?

      unless result?
        callback @createKiteNotFoundError args.query
        return

      if isLatest()
        result.kites = result.kites.map (kite) ->
          if args.query.name is 'kloud'
            kite.url = "https://#{getLatestURL()}/kloud/kite"
          kite

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


  createKite: (options, query) ->

    { kite } = options
    kiteName = kite.name

    # If its trying to create a klient kite instance
    # allow to use websockets by emptying the protocols_whitelist
    if kiteName is 'klient'
      options.transportOptions = { protocols_whitelist: [] }
    else if kiteName is 'kloud'
      options.autoReconnect = no

    kite = KontrolJS::createKite.call this, options

    if query?

      queryString = KiteCache.generateQueryString query

      kite.on 'close', (event) =>

        return  unless event?.code is 1002

        kite.options.autoReconnect = no
        KiteCache.unset query

        cc = kd.singletons.computeController

        if kiteInstance = @kites[kiteName]?['singleton']
          { waitingPromises } = kiteInstance
          delete @kites[kiteName]['singleton']

        else if machine = cc.findMachineFromQueryString queryString
          kiteInstance = @kites[kiteName][machine.uid]
          { waitingPromises } = kiteInstance  if kiteInstance
          delete @kites[kiteName][machine.uid]

          correlationName  = machine.uid
          transportOptions = { checkAlternatives: no }

        kiteInstance?.disconnect?()

        @getKite { name: kiteName, queryString, transportOptions
          correlationName, waitingPromises }

    return kite


  followConnectionStates: (kite, machineUId) ->

    kd.singletons.mainController.ready ->
      # Machine.uid is kite correlation name
      cc = kd.singletons.computeController

      emit = (status) ->
        if cc.findMachineFromMachineUId(machineUId)?.isRunning?()
          cc.emit "#{status}-#{machineUId}"

      kite.on 'open',      -> emit 'connected'
      kite.on 'close',     -> emit 'disconnected'
      kite.on 'reconnect', -> emit 'reconnecting'


  getKite: (options = {}) ->

    # Get options
    { name, correlationName, region, transportOptions, waitingPromises
      username, environment, version, queryString } = options

    # If no `correlationName` is defined assume this kite instance
    # is a singleton kite instance and keep track of it with this keyword
    correlationName ?= 'singleton'

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
              .then (res) ->
                KiteLogger.success name, args.first, args
                return res
              .catch (err) ->
                KiteLogger.failed name, args.first, args
                throw err
          )

    query ?= { name, region, username, version, environment }
    # Query kontrol
    @fetchKite { query }

      # Connect to kite
      .then (transport) ->

        kite.setTransport transport
        return transport

      # Report error
      .catch (err) =>

        kd.warn '[KodingKontrol] ', err

        # Instead parsing message we need to define a code or different
        # name for `No kite found` error in kite.js ~ FIXME GG
        if err and err.name is 'KiteError' and /^No kite found/.test err.message
          @setCachedKite name, correlationName
          kite.invalid = err

        return err

    return kite
