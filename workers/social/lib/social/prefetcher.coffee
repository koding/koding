cachedRoutes    = {}
cachedRouteTTL  = {}
cachingTimeInMS = 30000

prefetchedFeeds = {}

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
    queue.fin()

  dash queue, ()->
    callback null, prefetchedFeeds


inProgress = no
repeatFetchingItems= (options)->
  return  if inProgress
  inProgress = yes

  timer = setTimeout ->
    inProgress = no
    console.log "timeout reached, setting inProgress to false"
  , 120000

  {client} = options
  prefetchAll options, client, (err, data)->
    clearTimeout timer
    inProgress = no
    if err
      return console.log "An error occured while fetching in interval", err

module.exports = (options = {}, callback)->

  options.intro   ?= no
  options.client or= {}
  options.client.context or= {}
  options.client.context.group or= "koding"

  {bongoModels, client} = options

  route = getRoute options
  if cachedRoutes[route]
    prefetchedFeeds = cachedRoutes[route]
    callback null, prefetchedFeeds
    if (Date.now() - (cachedRouteTTL[route] || 0)  > cachingTimeInMS)
      repeatFetchingItems options
  else
    repeatFetchingItems options
    callback null, {}
