Bongo          = require "bongo"
{Relationship} = require "jraphical"
request        = require 'request'

{secure, daisy, dash, signature, Base} = Bongo
{throttle} = require 'underscore'


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
        fetchPopularPosts:
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
        searchTopics:
          (signature Object, Function)

        fetchProfileFeed:
          (signature Object, Function)

    schema             :
      id               : Number
      name             : String
      creatorId        : Number
      groupName        : String
      purpose          : String
      secretKey        : String
      typeConstant     : String
      privacyConstant  : String
      createdAt        : Date
      updatedAt        : Date
    sharedEvents    :
      static        : [
        { name: 'broadcast' }
      ]

  JAccount = require '../account'

  Validators = require '../group/validators'
  {permit}   = require '../group/permissionset'

  {fetchGroup} = require "./helper"

  @generateChannelName = ({groupSlug, apiChannelType, apiChannelName})->
    return "socialapi-\
    group-#{groupSlug}-\
    type-#{apiChannelType}-\
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

  @cycleChannel =do->
    cycleChannel = (options, callback=->)->
      JName = require '../name'
      name = @generateChannelName options
      JName.cycleSecretName name, (err, oldSecretName, newSecretName)=>
        return callback err if err
        routingKey = "socialapi.channelsecret.#{oldSecretName}.cycleChannel"
        @emit 'broadcast', routingKey, null
        return callback null
    return throttle cycleChannel, 5000

  cycleChannel:(callback)->
    options =
      groupSlug     : @groupName
      apiChannelType: @typeConstant
      apiChannelName: @name

    @constructor.cycleChannel options, callback

  @fetchActivities = secure (client, options = {}, callback)->
    options.channelId = options.id
    @doRequest 'fetchChannelActivities', client, options, callback

  @searchTopics = secure (client, options = {}, callback)->
    @doRequest 'searchTopics', client, options, callback

  @fetchProfileFeed = secure (client, options = {}, callback)->
    @doRequest 'fetchProfileFeed', client, options, callback

  @fetchPopularTopics = secure (client, options = {}, callback)->
    @doRequest 'fetchPopularTopics', client, options, callback

  @fetchPopularPosts = secure (client, options = {}, callback)->
    @doRequest 'fetchPopularPosts', client, options, callback

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

  @followUser = secure (client, options, callback)->
    {connection:{delegate}} = client
    return callback {message: "Access denied"}  if delegate.type isnt 'registered'
    unless options.followee
      return callback {message: "Followee is not set"}

    delegate.createSocialApiId (err, actorId) ->
      return callback err  if err
      options.followee.createSocialApiId (err, targetId) ->
        return callback err  if err
        {followUser, unfollowUser} = require './requests'
        data =
          accountId   : actorId
          creatorId   : targetId
        method = if options.unfollow then unfollowUser else followUser
        method data, callback

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
