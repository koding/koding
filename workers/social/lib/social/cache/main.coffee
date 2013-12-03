cache           = {}
cachingTimeInMS = 30000

repeatFetchingItems = (fetcherFn, route, options)->
  inProgress = cache[route]?.inProgress || no

  return  if inProgress

  cache[route] = inProgress : yes

  cache[route].timer = setTimeout ->
    cache[route].inProgress = no
    console.log "timeout reached, setting inProgress to false"
  , 120000

  fetcherFn options, (err, data)->
    clearTimeout cache[route].timer
    cache[route].inProgress = no

    if err
      return console.log "An error occured while fetching in interval", err

    cache[route].ttl  = Date.now()
    cache[route].data = data

module.exports = class Cache
  @fetch: (fetcherFn, route, options, callback)->
    if cache[route]
      {data, ttl} = cache[route]
      callback null, data

      if (Date.now() - (ttl || 0)  > cachingTimeInMS)
        repeatFetchingItems fetcherFn, route, options
    else
      repeatFetchingItems fetcherFn, route, options
      callback null, {}

  @remove: (route, data)-> delete cache[route]
