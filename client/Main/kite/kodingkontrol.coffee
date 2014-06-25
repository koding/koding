class KodingKontrol extends (require 'kontrol')

  constructor: ->
    super @getAuthOptions()

    @kites = {}
    @regions = {}

  getAuthOptions: ->
    autoConnect     : no
    url             : KD.config.newkontrol.url
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
    { os, terminal } = KD.config.kites
    # TODO: this could be more elegant:
    {
      oskite    : os.version
      terminal  : terminal.version
    }[name] ? ''

  injectQueryParams: (args) ->
    args.query.version ?= @getVersion args.query.name
    args.query.username = KD.config.kites.kontrol.username
    args.query.environment = KD.config.environment
    args

  getCachedKite: (name, correlationName) ->
    @kites[name]?[correlationName]

  setCachedKite: (name, correlationName, kite) ->
    @kites[name] ?= {}
    @kites[name][correlationName] = kite

  hasKite: (options = {}) ->
    { name, correlationName, region } = options
    return (kite = @getCachedKite name, correlationName)?

  fetchRegion: (correlationName, region) ->
    if region ?= @regions[correlationName]
      return Promise.resolve region

    new Promise (resolve, reject) =>
      KD.remote.api.JVM.fetchVmRegion correlationName, (err, region) =>

        if err
          warn err
          return reject err

        if not region
          # It's fallbacking to 'sj' for now but
          region = 'sj'

        @regions[correlationName] = region

        resolve region

  fetchVmInfo: (correlationName) ->
    new Promise (resolve, reject) ->
      KD.remote.api.JVM.fetchVmInfo correlationName, (err, info) =>
        return reject err                              if err
        return reject new Error "VM info not found!"   unless info?
        resolve info

  getWhoParams: (kiteName, correlationName) ->
    if kiteName in ['oskite', 'terminal']
      return vmName: correlationName
    { correlationName }

  getKiteByCorrelationName: (name, correlationName) ->
    kite = @getKiteProxy { name, correlationName }

    @fetchVmInfo(correlationName).then ({ region }) =>
      @fetchKite
        query : { name, region }
        who   : @getWhoParams name, correlationName
    .then(kite.bound 'setTransport')
    .then(kite.bound 'logTransportFailures')
    .catch(@error.bind this)

    kite

  getKiteProxy: (options) ->
    { name, correlationName } = options

    if (kite = @getCachedKite name, correlationName)?
      return kite

    konstructor = KodingKite.constructors[name]

    kite = new konstructor options

    @setCachedKite name, correlationName, kite

    kite

  getKite: (options = {}) ->
    { name, correlationName, region } = options

    kite = @getKiteProxy options

    @fetchRegion(correlationName, region).then (region) =>

      @fetchKite
        query : { name, region }
        who   : @getWhoParams name, correlationName

    .then(kite.bound 'setTransport')
    .then(kite.bound 'logTransportFailures')
    .catch(@error.bind this)

    kite

  error: (err)->
    warn err

    {message} = err
    message   = if message then message else err

    ErrorLog.create message
