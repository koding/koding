class KiteCache


  storage = LocalStorage.getStorage()


  @generateQueryString = (options) ->

    keys = [ "username", "environment", "name",
             "version", "region", "hostname", "id" ]

    query = ""

    for key in keys
      query += "/#{options[key] ? ""}"

    return query


  isKiteValid = (kite) ->

    return no  unless kite?.token?

    [header, body, rest...] = kite.token.split '.'

    return no  unless body

    try
      {exp} = JSON.parse atob body
    catch e
      warn "Failed to parse token:", e
      return no

    exp = +new Date exp * 1000
    now = +new Date

    return now < exp


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
    return


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
      warn "[KiteCache] PARSE ERROR", e
      return @unset query

    if kite.cachedAt?
      warn "[KiteCache] CACHE FOUND WITH OLD STYLE TIMESTAMP, REMOVING..."
      return @unset queryString

    else

      unless isKiteValid kite
        warn "[KiteCache] CACHE FOUND BUT ITS OUTDATED, REMOVING..."
        return @unset queryString

    return kite
