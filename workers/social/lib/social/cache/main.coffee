cache           = {}
cachingTimeInMS = 10000

repeatFetchingItems = (cacheKey, fetcherFn, fetcherFnOptions)->
  inProgress = cache[cacheKey]?.inProgress or no

  return  if inProgress

  cache[cacheKey] or= {}
  cache[cacheKey].inProgress = yes

  cache[cacheKey].timer = setTimeout ->
    cache[cacheKey].inProgress = no
    console.log "timeout reached, setting inProgress to false"
  , 120000

  fetcherFn fetcherFnOptions, (err, data)->
    clearTimeout cache[cacheKey].timer
    cache[cacheKey].inProgress = no

    if err
      return console.log "An error occured while fetching in interval", err

    cache[cacheKey].ttl  = Date.now()
    cache[cacheKey].data = data

module.exports = class Cache
  @fetch: (cacheKey, fetcherFn, fetcherFnOptions, callback)->
    {fallbackFn} = fetcherFnOptions
    if cache[cacheKey]
      {data, ttl} = cache[cacheKey]
      callback null, data or {}
      if (Date.now() - (ttl or 0)  > cachingTimeInMS)
        repeatFetchingItems cacheKey, fetcherFn, fetcherFnOptions
    else
      repeatFetchingItems cacheKey, fetcherFn, fetcherFnOptions
      (fallbackFn? callback, fetcherFnOptions) or (callback null, {})

  @remove: (cacheKey, data)-> delete cache[cacheKey]
