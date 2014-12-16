class KiteCache


  storage = LocalStorage.getStorage()


  @generateQueryString = (options) ->

    keys = [ "username", "environment", "name",
             "version", "region", "hostname", "id" ]

    query = ""

    for key in keys
      query += "/#{options[key] ? ""}"

    return query


  signed = (queryString) -> "KITE_#{queryString}"


  proxifyTransport = (kite) ->

    if kite.kite.name is 'klient'
      kite.url = KD.utils.proxifyTransportUrl kite.url

    return kite


  @clearAll = ->

    for kite in (Object.keys storage) when /^KITE_/.test kite
      delete storage[kite]


  @unset = (query) ->

    if typeof query is 'object'
      query = @generateQueryString query

    delete storage[signed query]


  @cache = (query, kite) ->

    unless kite?
      return warn "[KiteCache] KITE NOT PROVIDED, IGNORING TO CACHE"

    queryString = @generateQueryString query
    kite = proxifyTransport kite
    LocalStorage.setValue (signed queryString), (JSON.stringify kite)


  @get = (query) ->

    queryString = @generateQueryString query

    kite = storage[signed queryString]

    return  unless kite?

    try
      kite = JSON.parse kite
    catch e
      warn "parse failed", e
      @unset query
      kite = null

    return kite
