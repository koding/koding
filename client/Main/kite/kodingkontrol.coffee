class KodingKontrol extends KontrolJS = (require 'kontrol')

  constructor: (options = {})->

    @_kontrolUrl = options.kontrolUrl  if options.kontrolUrl?

    super @getAuthOptions()

    @kites   = {}
    @regions = {}


  getAuthOptions: ->

    @_lastUsedKey = Cookies.get 'clientId'

    autoConnect           : no
    autoReconnect         : no
    url                   : @_kontrolUrl ? KD.config.newkontrol.url
    auth                  :
      type                : 'sessionID'
      key                 : @_lastUsedKey
    transportClass        : SockJS
    transportOptions      :
      heartbeatTimeout    : 30 * 1000 # 30 seconds
      # Force XHR for all kind of kite connection
      protocols_whitelist : ['xhr-polling'] # , 'xhr-streaming']


  reauthenticate: (initial)->

    if @_lastUsedKey?
      if (Cookies.get 'clientId') isnt @_lastUsedKey
        # disconnect the old kontrol kite
        @kite?.disconnect()

    # reauthenticate with the current session token
    @authenticate @getAuthOptions()


  fetchKite: Promise.promisify (args, callback)->

    if (cachedKite = KiteCache.get args.query)?
      return callback null, @createKite cachedKite, args.query

    KontrolJS::fetchKite.call this, args, callback


  fetchKites: Promise.promisify (args = {}, callback) ->

    @reauthenticate()  unless @kite?

    {query} = args
    args    = @injectQueryParams args

    @kite.tell 'getKites', [args], (err, result) =>
      if err?
        callback err
        return

      unless result?
        callback @createKiteNotFoundError args.query
        return

      if query? and result.kites.length is 1
        KiteCache.cache query, result.kites.first

      callback null, @createKites result.kites
      return
    return


  getVersion: (name) ->
    return KD.config.kites[name].version ? '1.0.0'


  injectQueryParams: (args) ->

    args.query.version     ?= @getVersion args.query.name
    args.query.username    ?= KD.config.kites.kontrol.username
    args.query.environment ?= KD.config.environment

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

    konstructor = KodingKite.constructors[name]
    kite = new konstructor options

    @setCachedKite name, correlationName, kite

    return kite


  createKite: (options, query)->

    {kite} = options
    kiteName = kite.name

    # If its trying to create a klient kite instance
    # allow to use websockets by emptying the protocols_whitelist
    if kiteName is 'klient'
      options.transportOptions = protocols_whitelist: []

    kite = KontrolJS::createKite.call this, options

    if query?

      queryString = KiteCache.generateQueryString query

      kite.on 'close', (event)=>

        if event?.code is 1002 and \
           event?.reason is "Can't connect to server"

          kite.options.autoReconnect = no
          KiteCache.unset query




    return kite


  getKite: (options = {}) ->

    # Get options
    { name, correlationName, region, transportOptions,
      username, environment, version, queryString } = options

    # If no `correlationName` is defined assume this kite instance
    # is a singleton kite instance and keep track of it with this keyword
    correlationName ?= "singleton"

    # If queryString provided try to split it first
    # and if successful, use it as query
    if queryString? and queryObject = KD.utils.splitKiteQuery queryString
      query    = queryObject
      { name } = queryObject  if query.name

    # Check for cached version of requested kite with correlationName
    return kite  if (kite = @getCachedKite name, correlationName)?

    # Get Kite Proxy, it will be created at this point
    # since its not cached before
    kite = @getKiteProxy { name, correlationName, transportOptions }

    if kite.options.name is 'klient'
      kite
        .on 'close', ->
          if not kite.isDisconnected and kite.transport?.options.autoReconnect
            KodingKontrol.dcNotification ?= new KDNotificationView
              title     : 'Trying to reconnect...'
              type      : 'tray'
              duration  : 999999
        .on 'open', ->
          KodingKontrol.dcNotification?.destroy()
          KodingKontrol.dcNotification = null

    # Query kontrol
    @fetchKite
      query : query ? { name, region, username, version, environment }

    # Connect to kite
    .then(kite.bound 'setTransport')
    .then(kite.bound 'logTransportFailures')

    # Report error
    .catch (err)=>

      warn "[KodingKontrol] ", err

      # Instead parsing message we need to define a code or different
      # name for `No kite found` error in kite.js ~ FIXME GG
      if err and err.name is "KiteError" and /^No kite found/.test err.message
        @setCachedKite name, correlationName
        kite.invalid = err

      {message} = err
      message   = if message then message else err

      ErrorLog.create message

    return kite

