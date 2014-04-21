Bongo          = require "bongo"
{Relationship} = require "jraphical"
request        = require 'request'

{secure, daisy, dash, signature, Base} = Bongo
{uniq} = require 'underscore'


module.exports = class SocialChannel extends Base
  @share()

  @set
    sharedMethods :
      static      :
        fetchActivities     :
          (signature Object, Function)
        fetchChannels     :
          (signature Object, Function)
        fetchParticipants :
          (signature Object, Function)
        fetchPopularTopics:
          (signature Object, Function)
        fetchPinnedMessages:
          (signature Object, Function)
        pinMessage    :
          (signature Object, Function)
        unpinMessage  :
          (signature Object, Function)
        follow:
          (signature Object, Function)
        unfollow:
          (signature Object, Function)
        fetchFollowedChannels:
          (signature Object, Function)

    schema             :
      id               : Number
      name             : String
      creatorId        : Number
      group            : String
      purpose          : String
      secretKey        : String
      type             : String
      privacy          : String
      createdAt        : Date
      updatedAt        : Date

  JAccount = require '../account'

  Validators = require '../group/validators'
  {permit}   = require '../group/permissionset'

  {fetchGroup} = require "./helper"

  @generateChannelName = ({groupSlug, apiChannelType, apiChannelName})->
    return "socialapi-
group-#{groupSlug}-
type-#{apiChannelType}-
name-#{apiChannelName}"

  @fetchSecretChannelName =(options, callback)->
    {groupSlug, apiChannelType, apiChannelName} = options
    name = @generateChannelName options
    JName = require '../name'
    JName.fetchSecretName name, (err, secretName, oldSecretName)->
      # just to know, how many parameters does this function return
      # callback err, secretName, oldSecretName
      if err then callback err
      else callback null, "socialapi.channelsecret.#{secretName}",
        if oldSecretName then "socialapi.channelsecret.#{oldSecretName}"

  @fetchActivities = secure (client, options = {}, callback)->
    options.channelId = options.id
    @doRequest 'fetchChannelActivities', client, options, callback

  @fetchPopularTopics = secure (client, options = {}, callback)->
    @doRequest 'fetchPopularTopics', client, options, callback

  @fetchChannels = secure (client, options = {}, callback)->
    @doRequest 'fetchGroupChannels', client, options, callback

  @fetchFollowedChannels = secure (client, options = {}, callback)->
    @doRequest 'fetchFollowedChannels', client, options, callback

  @fetchPinnedMessages = permit 'pin posts',
    success: (client, options, callback)->
      @doRequest 'fetchPinnedMessages', client, options, callback

  @pinMessage = permit 'pin posts',
    success:  (client, options, callback)->
      unless options.messageId
        return callback {message: "Message id is not set for pinning "}
      @doRequest 'pinMessage', client, options, callback

  @unpinMessage = permit 'like posts',
    success:  (client, options, callback)->
      unless options.messageId
        return callback {message: "Message id is not set for un-pinning "}
      @doRequest 'unpinMessage', client, options, callback

  @follow = secure (client, options, callback)->
    unless options.channelId
      return callback {message: "Channel id is not set for following a topic"}
    @doRequest 'followTopic', client, options, callback

  @unfollow = secure (client, options, callback)->
    unless options.channelId
      return callback {message: "Channel id is not set for topic unfollowing"}
    @doRequest 'unfollowTopic', client, options, callback

  @doRequest = (funcName, client, options, callback)->
    fetchGroup client, (err, group)->
      return callback err if err
      {connection:{delegate}} = client
      delegate.createSocialApiId (err, socialApiId)->
        return callback err if err

        options.groupName = group.slug
        options.accountId = socialApiId

        requests = require './requests'
        requests[funcName] options, callback
