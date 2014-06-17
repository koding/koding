{dash}         = require 'bongo'
SocialChannel  = require '../models/socialapi/channel'
SocialMessage  = require '../models/socialapi/message'


module.exports = (options={}, callback)->
  {bongoModels, client} = options
  unless bongoModels
    console.error "bongo is not defined"
    return callback null, []


  fetchPopularTopics = (bongoModels, client, cb)->
    options =
      type        : "weekly"
      channelName : "koding"
      limit       : 5

    SocialChannel.fetchPopularTopics client, options, cb

  defaultOptions =
    limit: 5

  fetchFollowedChannels = (bongoModels, client, cb)->
    SocialChannel.fetchFollowedChannels client, defaultOptions, cb

  fetchPinnedMessages = (bongoModels, client, cb)->
    SocialChannel.fetchPinnedMessages client, defaultOptions, cb

  fetchPrivateMessages = (bongoModels, client, cb)->
    SocialMessage.fetchPrivateMessages client, defaultOptions, cb

  fetchGroupActivities = (bongoModels, client, cb)->
    SocialChannel.fetchGroupActivities client, {}, cb

  reqs = [
    { fn:fetchPopularTopics,     key: 'popularTopics'    }
    { fn:fetchFollowedChannels,  key: 'followedChannels' }
    { fn:fetchPinnedMessages,    key: 'pinnedMessages'   }
    { fn:fetchPrivateMessages,   key: 'privateMessages'  }
    { fn:fetchGroupActivities,   key: 'publicFeed'       }
  ]

  queue = []
  queue.localPrefetchedFeeds = {}
  queue = reqs.map (req)-> ->
    req.fn bongoModels, client, (err, data)->
      queue.localPrefetchedFeeds or= {}
      queue.localPrefetchedFeeds[req.key] = data
      queue.fin()

  dash queue, ()-> callback null, queue.localPrefetchedFeeds
