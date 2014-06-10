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
        byId              :
          (signature Object, Function)
        byName            :
          (signature Object, Function)
        fetchActivities   :
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
        updateLastSeenTime:
          (signature Object, Function)
        glancePinnedPost:
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

  { fetchGroup, secureRequest,
    doRequest, permittedRequest,
    ensureGroupChannel, fetchGroup } = require "./helper"

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

  @checkChannelParticipation = secureRequest
    fnName   : 'checkChannelParticipation'
    validate : ['name', 'type']


  # byId - fetch channel by id
  @byId = secureRequest
    fnName  : 'channelById'
    validate: ["id"]

  # byName - fetch channel by name
  @byName = secureRequest
    fnName  : 'channelByName'
    validate: ["name"]

  # searchTopics - search topics for autocompletion
  @searchTopics          = secureRequest fnName: 'searchTopics'

  # fetchProfileFeed - lists all activities of an account
  # within a specified group
  @fetchProfileFeed      = secureRequest fnName: 'fetchProfileFeed'

  # fetchPopularTopics - lists group specific popular topics
  # it can be daily, weekly, monthly
  @fetchPopularTopics    = secureRequest fnName: 'fetchPopularTopics'

  # fetchPopularPosts -  lists group specific popular posts
  # it can be daily, weekly, monthly
  @fetchPopularPosts     = secureRequest fnName: 'fetchPopularPosts'

  # fetchChannels - lists group's topic channels
  @fetchChannels         = secureRequest fnName: 'fetchGroupChannels'

  # fetchFollowedChannels - lists followed channels(topics) of an account
  @fetchFollowedChannels = secureRequest fnName: 'fetchFollowedChannels'

  # follow - endpoint for users to follow topics
  @follow = secureRequest
    fnName  : 'followTopic'
    validate: ["channelId"]

  # unfollow - endpoint for users to give up following a channel
  @unfollow = secureRequest
    fnName  : 'unfollowTopic'
    validate: ["channelId"]

  # updateLastSeenTime - updates user's channel presence data
  @updateLastSeenTime = secureRequest
    fnName  : 'updateLastSeenTime'
    validate: ["channelId"]

  # glancePinnedPost - updates user's lastSeenDate for pinned posts
  @glancePinnedPost = secureRequest
    fnName  : 'glancePinnedPost'
    validate: ["messageId"]

  # fetchPinnedMessages - fetch user's pinned messages
  @fetchPinnedMessages = permittedRequest
    permissionName: 'pin posts'
    fnName        : 'fetchPinnedMessages'

  # pinMessage - pin a message for future referance
  @pinMessage = permittedRequest
    permissionName: 'pin posts'
    fnName        : 'pinMessage'
    validate      : ['messageId']

  # unpinMessage - remove a pinned message from followed posts
  @unpinMessage = permittedRequest
    permissionName: 'pin posts'
    fnName        : 'unpinMessage'
    validate      : ['messageId']

  # fetchActivities - fetch activities of a channel
  @fetchActivities = secure (client, options, callback)->
    options.channelId = options.id
    doRequest 'fetchChannelActivities', client, options, callback

  # fetchGroupActivities - fetch public activities of a group
  @fetchGroupActivities = secure (client, options, callback)->
    ensureGroupChannel client, (err, socialApiChannelId)->
      return callback err if err
      return callback { message: "Channel Id is not set" } unless socialApiChannelId

      options.id = socialApiChannelId
      SocialChannel.fetchActivities client, options, callback

  # followUser - a user follows a user
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
