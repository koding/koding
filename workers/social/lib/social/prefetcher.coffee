cachedRoutes    = {}
cachedRouteTTL  = {}
cachingTimeInMS = 30000

prefetchedFeeds = null

intervalOptions = {}

{dash}  = require 'bongo'
JTag    = require './models/tag'
JApp    = require './models/app'

fetchMembersFromGraph = (bongoModels, client, cb)->
  return cb null, [] unless bongoModels
  {JGroup}  = bongoModels
  groupName = client?.context?.group or 'koding'
  JGroup.one slug: groupName, (err, group)->
    return cb null, [] if err
    group._fetchMembersFromGraph client, {}, cb

fetchActivityFromGraph = (bongoModels, client, cb)->
  return cb null, [] unless bongoModels
  {CActivity} = bongoModels
  options = facets : "Everything"

  CActivity._fetchPublicActivityFeed client, options, (err, data)->
    return cb null, [] if err
    return cb null, data

# while implementing profile prefetching we will need
# a custom route for prefetched content
getRoute = (options)-> return "scriptblock"

prefetchAll = (options, client, callback) ->

  {bongoModels, client, intro} = options

  # set interval options for later use
  intervalOptions = options

  prefetchedFeeds = {}
  queue          = []
  defaultOptions =
    limit : 20
    skip  : 0
    sort  : 'counts.followers' : -1

  queue.push ->
    fetchMembersFromGraph bongoModels, client, (err, members)->
      prefetchedFeeds['members.main'] = members  if members
      queue.fin()

  # Modified this function to fetch groups' tags
  # also we can return topics for all groups
  queue.push ->
    JTag._some client, {}, defaultOptions, (err, topics)->
      prefetchedFeeds['topics.main'] = topics  if topics
      queue.fin()

  # This is not koding specific so we can return this to every group
  queue.push ->
    JApp.some {"approved": true}, defaultOptions, (err, apps)->
      prefetchedFeeds['apps.main'] = apps  if apps
      queue.fin()

  # we are fetching group activity, so again we can return this one for all groups
  queue.push ->
    fetchActivityFromGraph bongoModels, client, (err, activity)->
      prefetchedFeeds['activity.main'] = activity  if activity
      queue.fin()

  queue.push ->
    route = getRoute options
    cachedRoutes[route] = prefetchedFeeds
    cachedRouteTTL[route] = Date.now()
    console.log "#{route} cache is updated"
    queue.fin()

  dash queue, ()->
    callback null, prefetchedFeeds


repeatFetchingItems = ->
  return console.log "interval options are not valid" unless intervalOptions
  {client} = intervalOptions
  prefetchAll intervalOptions, client, (err, data)->
    if err
      return console.log "An error occured while fetching in interval", err
    else
      console.log "updating in interval"

intervalFetcher = setInterval repeatFetchingItems, 25000

module.exports = (options = {}, callback)->

  options.intro   ?= no
  options.client or= {}
  options.client.context or= {}
  options.client.context.group or= "koding"

  {bongoModels, client} = options

  route = getRoute options
  if cachedRoutes[route]
    if (Date.now() - (cachedRouteTTL[route] || 0)  < cachingTimeInMS)
      console.log "#{route} cache is still valid"
      prefetchedFeeds = cachedRoutes[route]
      return callback null, prefetchedFeeds

  return prefetchAll options, client, callback
