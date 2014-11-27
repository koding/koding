class KodingKontrol extends (require 'kontrol')

  constructor: (options = {})->

    @_kontrolUrl = options.kontrolUrl  if options.kontrolUrl?

    super @getAuthOptions()

    @kites   = {}
    @regions = {}

    @reauthenticate()

  getAuthOptions: ->
    autoConnect     : no
    url             : @_kontrolUrl ? KD.config.newkontrol.url
    auth            :
      type          : 'sessionID'
      key           : Cookies.get 'clientId'
    transportClass  : SockJS
    transportOptions:
      heartbeatTimeout: 30 * 1000 # 30 seconds


  reauthenticate: ->
    # disconnect the old kontrol kite
    @kite?.disconnect()
    # reauthenticate with the current session token
    @authenticate @getAuthOptions()

  fetchKites: (query = {}, rest...) ->
    super (@injectQueryParams query), rest...

  getVersion: (name) ->
    return '1.0.0'  unless name?
    { os, terminal, klient, kloud } = KD.config.kites
    # TODO: this could be more elegant:
    {
      oskite   : os.version
      terminal : terminal.version
      klient   : klient.version
      kloud    : kloud.version
    }[name] ? ''

  injectQueryParams: (args) ->

    args.query.version     ?= @getVersion args.query.name
    args.query.username    ?= KD.config.kites.kontrol.username
    args.query.environment ?= KD.config.environment

    return args

  getCachedKite: (name, correlationName) ->
    @kites[name]?[correlationName]

  setCachedKite: (name, correlationName, kite) ->
    @kites[name] ?= {}
    @kites[name][correlationName] = kite

  hasKite: (options = {}) ->
    { name, correlationName, region } = options
    return (kite = @getCachedKite name, correlationName)?

  getWhoParams: (kiteName, correlationName) ->
    if kiteName in ['oskite', 'terminal']
      return vmName: correlationName
    return { correlationName }

  getKiteProxy: (options) ->

    { name, correlationName } = options

    konstructor = KodingKite.constructors[name]
    kite = new konstructor options

    @setCachedKite name, correlationName, kite

    return kite


  getKite: (options = {}) ->

    @reauthenticate()  unless @kite?

    # Get options
    { name, correlationName, region, transportOptions,
      username, environment, queryString } = options

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
      query : query ? { name, region, username, environment }

      # TODO : Implement optional kite.who
      # who  : @getWhoParams name, correlationName

    # Connect to kite
    .then(kite.bound 'setTransport')
    .then(kite.bound 'logTransportFailures')

    # Report error
    .catch (err)=>

      warn "[KodingKontrol] ", err

      # Instead parsing message we need to define a code or different
      # name for `No kite found` error in kite.js ~ FIXME GG
      if err and err.name is "KiteError" and /^No kite found/.test err.message
        @setCachedKite name, correlationName, null
        kite.invalid = err

      {message} = err
      message   = if message then message else err

      ErrorLog.create message

    return kite

