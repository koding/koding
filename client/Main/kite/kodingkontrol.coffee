class KodingKontrol extends (require 'kontrol')

  constructor: (options = {})->

    @_kontrolUrl = options.kontrolUrl  if options.kontrolUrl?

    super @getAuthOptions()

    @kites = {}
    @regions = {}

  getAuthOptions: ->
    autoConnect     : no
    url             : @_kontrolUrl ? KD.config.newkontrol.url
    auth            :
      type          : 'sessionID'
      key           : Cookies.get 'clientId'
    transportClass  : SockJS


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

  fetchVmInfo: (correlationName) ->
    new Promise (resolve, reject) ->
      KD.remote.api.JVM.fetchVmInfo correlationName, (err, info) =>
        return reject err                              if err
        return reject new Error "VM info not found!"   unless info?
        resolve info

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

    # Get options
    { name, correlationName, region,
      username, environment, queryString } = options

    # If queryString provided try to split it first
    # and if successful, use it as query
    if queryString? and queryObject = KD.utils.splitKiteQuery queryString
      { name } = query = queryObject

    # Check for cached version of requested kite with correlationName
    return kite  if (kite = @getCachedKite name, correlationName)?

    # Get Kite Proxy, it will be created at this point
    # since its not cached before
    kite = @getKiteProxy { name, correlationName }

    # Query kontrol
    @fetchKite
      query : query ? { name, region, username, environment }

      # TODO : Implement optional kite.who
      # who  : @getWhoParams name, correlationName

    # Connect to kite
    .then(kite.bound 'setTransport')
    .then(kite.bound 'logTransportFailures')

    # Report error
    .catch(@error.bind this)

    return kite


  error: (err)->

    warn "[KodingKontrol] ", err

    {message} = err
    message   = if message then message else err

    ErrorLog.create message
