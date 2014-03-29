class KodingKontrol extends (require 'kontrol')

  constructor: ->
    super
      url     : KD.config.newkontrol.url
      auth    :
        type  : 'sessionID'
        key   : Cookies.get 'clientId'

    @kites = {}

  fetchKites: (query = {}, rest...) ->
    super (@injectQueryParams query), rest...

  getVersion: (name) ->
    return '1.0.0'  unless name?
    # TODO: for now I am just hardcoding these versions:
    {
      oskite    : '0.1.8'
      terminal  : '0.0.1'
    }[name] ? '1.0.0'

  injectQueryParams: (query) ->
    query.version = @getVersion query.name
    query.username = 'koding'
    query.environment = KD.config.environment
    query

  getCachedKite: (name, correlationName) ->
    @kites[name]?[correlationName]

  setCachedKite: (name, correlationName, kite) ->
    @kites[name] ?= {}
    @kites[name][correlationName] = kite

  getKite: (options = {}) ->
    { name, correlationName, region } = options

    if (kite = @getCachedKite name, correlationName)?
      return kite

    konstructor = KodingKite.constructors[name]

    kite = new konstructor options

    @setCachedKite name, correlationName, kite

    @fetchKite({ name, region }).then kite.bound 'setTransport'

    return kite
