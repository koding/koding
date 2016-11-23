async          = require 'async'
SocialChannel  = require '../models/socialapi/channel'
SocialMessage  = require '../models/socialapi/message'
JAccount       = require '../models/account'
KodingError    = require '../error'


module.exports = (options = {}, callback) ->
  { client, entryPoint, params, session } = options
  { clientId: sessionToken } = session  if session

  defaultOptions =
    limit: 5

  fetchPopularPosts = (cb) ->
    opt =
      channelName : params?.section or 'Public'
      limit       : 10

    SocialChannel.fetchPopularPosts client, opt, cb

  fetchPopularTopics = (cb) ->
    opt =
      type        : 'weekly'
      channelName : 'koding'
      limit       : 5

    SocialChannel.fetchPopularTopics opt, cb

  fetchFollowedChannels = (cb) ->
    options  =
       limit : 8

    SocialChannel.fetchFollowedChannels client, options, cb

  fetchPinnedMessages = (cb) ->
    SocialChannel.fetchPinnedMessages client, defaultOptions, cb

  fetchPrivateMessages = (cb) ->
    options =
      limit : 10

    SocialMessage.fetchPrivateMessages client, options, cb

  fetchGroupActivities = (cb) ->
    SocialChannel.fetchGroupActivities client, { sessionToken }, cb

  fetchChannelActivities = (channelName, cb) ->
    # fetch channel first
    SocialChannel.byName client, { name: channelName }, (err, data) ->
      return cb err if err
      return cb new KodingError 'channel is not set'  unless data?.channel

      # then fetch activity with channel id
      SocialChannel.fetchActivities client, { id: data.channel.id, sessionToken }, cb

  fetchProfileFeed = (client, params, cb) ->
    JAccount.one { 'profile.nickname': entryPoint.slug }, (err, account) ->
      return cb err if err
      return cb new KodingError 'account not found'  unless account
      SocialChannel.fetchProfileFeed client, { targetId: account.socialApiId }, cb

  fetchActivitiesForNavigatedURL = (params, cb) ->
    return cb null, null unless params

    switch params.section
      when 'Topic'           then fetchChannelActivities params.slug, cb
      when 'Message'         then SocialChannel.fetchActivities client, { id: params.slug, sessionToken }, cb
      when 'Post'            then SocialMessage.bySlug client, { slug: params.slug }, cb
      when 'Announcement'    then cb new KodingError 'announcement not implemented'
      else fetchGroupActivities cb

  reqs = [
    { fn:fetchPopularPosts,      key: 'popularPosts' }
    { fn:fetchFollowedChannels,  key: 'followedChannels' }
    # pinned message channel is no-longer used
    # { fn:fetchPinnedMessages,    key: 'pinnedMessages'   }
    { fn:fetchPrivateMessages,   key: 'privateMessages' }
  ]

  handleQueue fetchActivitiesForNavigatedURL, reqs, params, callback


handleQueue = (fetchActivitiesForNavigatedURL, reqs, params, callback) ->

  queue = reqs.map (req) -> (fin) ->
    req.fn (err, data) ->
      queue.localPrefetchedFeeds or= {}
      queue.localPrefetchedFeeds[req.key] = data
      fin()

  queue.push (fin) ->
    fetchActivitiesForNavigatedURL params, (err, data) ->
      queue.localPrefetchedFeeds or= {}

      res =
        name:    params?.name    or 'Activity'
        section: params?.section or 'Public'
        slug:    params?.slug    or '/'
        data:    data

      queue.localPrefetchedFeeds.navigated = res unless err?
      fin()

  async.parallel queue, -> callback null, queue.localPrefetchedFeeds
