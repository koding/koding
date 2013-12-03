cache           = {}
cachingTimeInMS = 30000

repeatFetchingItems = (fetcherFn, cacheKey, options)->
  inProgress = cache[cacheKey]?.inProgress || no

  return  if inProgress

  cache[cacheKey] = inProgress : yes

  cache[cacheKey].timer = setTimeout ->
    cache[cacheKey].inProgress = no
    console.log "timeout reached, setting inProgress to false"
  , 120000

  fetcherFn options, (err, data)->
    clearTimeout cache[cacheKey].timer
    cache[cacheKey].inProgress = no

    if err
      return console.log "An error occured while fetching in interval", err

    cache[cacheKey].ttl  = Date.now()
    cache[cacheKey].data = data

module.exports = class Cache
  @fetch: (fetcherFn, cacheKey, options, callback)->
    if cache[cacheKey]
      {data, ttl} = cache[cacheKey]
      callback null, data

      if (Date.now() - (ttl || 0)  > cachingTimeInMS)
        repeatFetchingItems fetcherFn, cacheKey, options
    else
      repeatFetchingItems fetcherFn, cacheKey, options
      callback null, {}

  @remove: (cacheKey, data)-> delete cache[cacheKey]
