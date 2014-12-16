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
    return


  @cache = (query, kite) ->

    unless kite?
      return warn "[KiteCache] KITE NOT PROVIDED, IGNORING TO CACHE"

    queryString = @generateQueryString query
    kite = proxifyTransport kite
    kite.cachedAt = +new Date()

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

      cachedAt = new Date kite.cachedAt
      now      = new Date

      # Add 24 hours on top of cached at date
      cachedAt.setHours cachedAt.getHours() + 24

      if cachedAt < now
        warn "[KiteCache] CACHE FOUND BUT OUTDATED, REMOVING..."
        return @unset queryString

    else
      warn "[KiteCache] CACHE FOUND BUT DOESNT HAVE TIMESTAMP, REMOVING..."
      return @unset queryString


    return kite
