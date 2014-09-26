{dash}         = require 'bongo'
SocialChannel  = require '../models/socialapi/channel'
SocialMessage  = require '../models/socialapi/message'
JAccount       = require '../models/account'


module.exports = (options={}, callback)->
  {client, entryPoint, params} = options

  defaultOptions =
    limit: 5

  fetchPopularPosts = (cb)->
    opt =
      channelName : params.section
      limit       : 25

    SocialChannel.fetchPopularPosts client, opt, cb

  fetchPopularTopics = (cb)->
    opt =
      type        : "weekly"
      channelName : "koding"
      limit       : 5

    SocialChannel.fetchPopularTopics opt, cb

  fetchFollowedChannels = (cb)->
    options  =
       limit : 9

    SocialChannel.fetchFollowedChannels client, options, cb

  fetchPinnedMessages = (cb)->
    SocialChannel.fetchPinnedMessages client, defaultOptions, cb

  fetchPrivateMessages = (cb)->
    SocialMessage.fetchPrivateMessages client, defaultOptions, cb

  fetchGroupActivities = (cb)->
    SocialChannel.fetchGroupActivities client, {}, cb

  fetchChannelActivities = (channelName, cb)->
    # fetch channel first
    SocialChannel.byName client, {name: channelName}, (err, data)->
      return cb err if err
      return cb { message: "channel is not set" } unless data?.channel

      # then fetch activity with channel id
      SocialChannel.fetchActivities client, {id: data.channel.id}, cb

  fetchProfileFeed = (client, params, cb)->
    JAccount.one {'profile.nickname': entryPoint.slug}, (err, account)->
      return cb err if err
      return cb { message: "account not found" } unless account
      SocialChannel.fetchProfileFeed client, {targetId: account.socialApiId}, cb

  fetchActivitiesForNavigatedURL = (params, cb)->
    return cb null, null unless params

    switch params.section
      when "Topic"           then fetchChannelActivities params.slug, cb
      when "Message"         then SocialChannel.fetchActivities client, {id: params.slug}, cb
      when "Post"            then SocialMessage.bySlug client, {slug: params.slug}, cb
      when "Announcement"    then cb {message: "announcement not implemented"}
      else fetchGroupActivities cb

  reqs = [
    { fn:fetchPopularPosts,      key: 'popularPosts'     }
    { fn:fetchFollowedChannels,  key: 'followedChannels' }
    { fn:fetchPinnedMessages,    key: 'pinnedMessages'   }
    { fn:fetchPrivateMessages,   key: 'privateMessages'  }
  ]

  queue = reqs.map (req)-> ->
    req.fn (err, data)->
      queue.localPrefetchedFeeds or= {}
      queue.localPrefetchedFeeds[req.key] = data
      queue.fin()

  queue.push ->
    fetchActivitiesForNavigatedURL params, (err, data)->
      queue.localPrefetchedFeeds or= {}

      res =
        name:    params?.name    or "Activity"
        section: params?.section or "Public"
        slug:    params?.slug    or "/"
        data:    data

      queue.localPrefetchedFeeds.navigated = res unless err?
      queue.fin()

  dash queue, ()-> callback null, queue.localPrefetchedFeeds
