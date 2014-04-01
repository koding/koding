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
      oskite    : '0.1.9'
      terminal  : '0.0.2'
    }[name] ? '1.0.0'

  injectQueryParams: (args) ->
    args.query.version = @getVersion args.query.name
    args.query.username = 'koding'
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
    if region
    then Promise.resolve region
    else Promise.reject new Error "TODO: implement vm region fetching"

  getWhoParams: (kiteName, correlationName) ->
    if kiteName in ['oskite', 'terminal']
      return vmName: correlationName
    { correlationName }

  getKite: (options = {}) ->
    { name, correlationName, region } = options

    if (kite = @getCachedKite name, correlationName)?
      return kite

    konstructor = KodingKite.constructors[name]

    kite = new konstructor options

    @setCachedKite name, correlationName, kite

    @fetchRegion(correlationName, region).then (region) =>

      @fetchKite
        query : { name, region }
        who   : @getWhoParams name, correlationName

    .then kite.bound 'setTransport'

    return kite
