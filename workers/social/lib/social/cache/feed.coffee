{dash}  = require 'bongo'
JTag    = require '../models/tag'
JNewApp    = require '../models/app'

localPrefetchedFeeds = {}

module.exports = (options={}, callback)->
  {bongoModels, client, intro} = options

  fetchMembersFromGraph = (bongoModels, client, cb)->
    return cb null, [] unless bongoModels
    {JGroup}  = bongoModels
    groupName = client?.context?.group or 'koding'
    JGroup.one slug: groupName, (err, group)->
      return cb null, [] if err
      group.fetchMembersFromGraph client, {}, cb

  fetchActivity = (bongoModels, client, cb)->
    return cb null, [] unless bongoModels
    {JNewStatusUpdate} = bongoModels
    # options = facets : "Everything"

    JNewStatusUpdate.fetchGroupActivity client, options, (err, data)->
      return cb null, [] if err
      return cb null, data

  fetchMostLikedActivity = (bongoModels, client, cb)->
    return cb null, [] unless bongoModels
    {JNewStatusUpdate} = bongoModels
    options.sort = 'meta.likes' : -1
    aDay = 24 * 60 * 60 * 1000
    options.from = Date.now() - aDay
    options.limit = 5

    JNewStatusUpdate.fetchGroupActivity client, options, (err, data)->
      return cb null, [] if err
      return cb null, data

  # set interval options for later use
  intervalOptions = options

  queue          = []
  defaultOptions =
    limit : 20
    skip  : 0
    sort  : 'counts.followers' : -1

  # queue.push ->
  #   fetchMembersFromGraph bongoModels, client, (err, members)->
  #     localPrefetchedFeeds['members.main'] = members  if members
  #     queue.fin()

  # Modified this function to fetch groups' tags
  # also we can return topics for all groups
  # queue.push ->
  #   JTag._some client, {}, defaultOptions, (err, topics)->
  #     localPrefetchedFeeds['topics.main'] = topics  if topics
  #     queue.fin()

  # This is not koding specific so we can return this to every group
  # queue.push ->
  #   JNewApp.some {"approved": true}, defaultOptions, (err, apps)->
  #     localPrefetchedFeeds['apps.main'] = apps  if apps
  #     queue.fin()

  # we are fetching group activity, so again we can return this one for all groups
  queue.push ->
    fetchActivity bongoModels, client, (err, activity)=>
      localPrefetchedFeeds['activity.main'] = activity  if activity
      queue.fin()

  queue.push ->
    fetchMostLikedActivity bongoModels, client, (err, activity)=>
      localPrefetchedFeeds['mostlikedactivity.main'] = activity  if activity
      queue.fin()

  dash queue, ()-> callback null, localPrefetchedFeeds
