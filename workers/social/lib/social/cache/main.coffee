cache           = {}
cachedRouteTTL  = {}
cachingTimeInMS = 30000

inProgress = no
repeatFetchingItems = (fetcherFn, route, options)->
  return  if inProgress
  inProgress = yes

  timer = setTimeout ->
    inProgress = no
    console.log "timeout reached, setting inProgress to false"
  , 120000

  fetcherFn options, (err, data)->
    clearTimeout timer
    inProgress = no
    if err
      return console.log "An error occured while fetching in interval", err

    cache[route] = data
    cachedRouteTTL[route] = Date.now()

module.exports = class Cache
  @fetch: (fetcherFn, route, options, callback)->
    if cache[route]
      data = cache[route]
      callback null, data

      if (Date.now() - (cachedRouteTTL[route] || 0)  > cachingTimeInMS)
        repeatFetchingItems fetcherFn, route, options
    else
      repeatFetchingItems fetcherFn, route, options
      callback null, {}

  @remove: (route, data)->
    delete cache[route]
    delete cachedRouteTTL[route]
