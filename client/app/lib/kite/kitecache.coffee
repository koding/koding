kd           = require 'kd'
LocalStorage = require '../localstorage'


module.exports = class KiteCache

  storage   = LocalStorage.getStorage()
  signature = 'KITE_v2_'

  @generateQueryString = (options) ->

    keys = [ 'username', 'environment', 'name',
             'version', 'region', 'hostname', 'id' ]

    query = ''

    for key in keys
      query += "/#{options[key] ? ""}"

    return query


  isKiteValid = (kite) ->

    return no  unless kite?.token?

    [header, body, rest...] = kite.token.split '.'

    return no  unless body

    try
      { exp } = JSON.parse atob body
    catch e
      kd.warn 'Failed to parse token:', e
      return no

    exp = +new Date exp * 1000
    now = +new Date

    return now < exp


  signed = (queryString) -> "#{signature}#{queryString}"


  @clearAll = ->

    for kite in (Object.keys storage) when ///^#{signature}///.test kite
      delete storage[kite]


  @unset = (query) ->

    return  unless query

    if typeof query is 'object'
      query = @generateQueryString query

    # if only name provided instead of a full query string
    # check existing keys for that name and unset those instead ~ GG
    else if (query.indexOf '/') < 0
      namedQuery = ///\/.*\/.*\/#{query}///
      for queryString of storage when namedQuery.test queryString
        delete storage[queryString]
      return

    ltr = ''
    rtl = ''

    # It may look crpytic but what it does is very simple;
    # It generates all possible version of given Kite query and removes
    # them from cache if they are exists. ~ GG
    #
    # For given query:
    #
    #   /gokmen/development/klient/0.1.79/public-region/gokmen/db4acb42-91de-4176-6bdb-5be303a67e17
    #
    # It produces and removes followings:
    #
    #   KITE_/gokmen//////
    #   KITE_///////db4acb42-91de-4176-6bdb-5be303a67e17
    #   KITE_/gokmen/development/////
    #   KITE_//////gokmen/db4acb42-91de-4176-6bdb-5be303a67e17
    #   KITE_/gokmen/development/klient////
    #   KITE_/////public-region/gokmen/db4acb42-91de-4176-6bdb-5be303a67e17
    #   KITE_/gokmen/development/klient/0.1.79///
    #   KITE_////0.1.79/public-region/gokmen/db4acb42-91de-4176-6bdb-5be303a67e17
    #   KITE_/gokmen/development/klient/0.1.79/public-region//
    #   KITE_///klient/0.1.79/public-region/gokmen/db4acb42-91de-4176-6bdb-5be303a67e17
    #   KITE_/gokmen/development/klient/0.1.79/public-region/gokmen/
    #   KITE_//development/klient/0.1.79/public-region/gokmen/db4acb42-91de-4176-6bdb-5be303a67e17
    #   KITE_/gokmen/development/klient/0.1.79/public-region/gokmen/db4acb42-91de-4176-6bdb-5be303a67e17
    #   KITE_/gokmen/development/klient/0.1.79/public-region/gokmen/db4acb42-91de-4176-6bdb-5be303a67e17

    for part, i in queryA = (query.split '/')[1..]
      ltr += "/#{part}"
      delete storage[signature + ltr + ('/' for x in [i...6]).join '']
      rtl = '/' + queryA[queryA.length - i - 1] + rtl
      delete storage[signature + (('/' for [i...6]).join '') + rtl]

    return


  @cache = (query, kite) ->

    unless kite?
      return kd.warn '[KiteCache] KITE NOT PROVIDED, IGNORING TO CACHE'

    queryString = @generateQueryString query

    LocalStorage.setValue (signed queryString), (JSON.stringify kite)


  @get = (query) ->

    queryString = @generateQueryString query

    kite = storage[signed queryString]

    return  unless kite?

    try
      kite = JSON.parse kite

    catch e
      kd.warn '[KiteCache] PARSE ERROR', e
      return @unset query

    if kite.cachedAt?
      kd.warn '[KiteCache] CACHE FOUND WITH OLD STYLE TIMESTAMP, REMOVING...'
      return @unset queryString

    else

      unless isKiteValid kite
        kd.warn '[KiteCache] CACHE FOUND BUT ITS OUTDATED, REMOVING...'
        return @unset queryString

    return kite
