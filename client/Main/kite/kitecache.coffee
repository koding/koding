class KiteCache

  storage = window.localStorage

  log = (rest...)->
    console.log "[KC] ", rest...


  generateQueryString = (options)->

    keys = [ "username", "environment", "name",
             "version", "region", "hostname", "id" ]

    query = ""

    for key in keys
      query += "/#{options[key] ? ""}"

    return query


  signed = (queryString)-> "KITE_#{queryString}"


  proxifyTransport = (kite)->

    if kite.kite.name is 'klient'
      kite.url = KD.utils.proxifyTransportUrl kite.url

    return kite

  @clearAll = ->

    for kite in (Object.keys storage) when /^KITE_/.test kite
      delete storage[kite]

    log "All Kite caches cleared."


  @unset = (query)->

    if typeof query is 'object'
      query = generateQueryString query

    delete storage[signed query]

    log "Kite cache cleared for #{query}"


  @cache = (query, kite)->

    queryString = generateQueryString query
    kite = proxifyTransport kite
    try storage[signed queryString] = JSON.stringify kite
    log "Kite cached with '#{queryString}' queryString."


  @get = (query)->

    queryString = generateQueryString query

    kite = storage[signed queryString]

    unless kite?
      log "Kite requested with '#{queryString}' queryString, but not found."
      return

    try
      kite = JSON.parse kite
      # log "CACHED KITE FOUND:", query, kite
    catch e
      warn "parse failed", e
      @unset query
      kite = null

    return kite
