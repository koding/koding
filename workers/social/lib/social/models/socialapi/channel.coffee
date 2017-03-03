async            = require 'async'
Bongo            = require 'bongo'
{ Relationship } = require 'jraphical'
request          = require 'request'
KodingError      = require '../../error'

{ secure, signature, Base } = Bongo
{ throttle } = require 'underscore'

module.exports = class SocialChannel extends Base
  @share()

  @set
    classAttributes:
      # while sending XHR requests via bongo, we are batching those requests
      # but SocialChannel requests will not be batched
      bypassBatch   : yes

    sharedMethods :
      static      :
        byId                 :
          (signature Object, Function)
        byName               :
          (signature Object, Function)
        fetchChannels        :
          (signature Object, Function)
        fetchParticipants    :
          (signature Object, Function)
        listParticipants     :
          (signature Object, Function)
        addParticipants      :
          (signature Object, Function)
        removeParticipants   :
          (signature Object, Function)
        leave                :
          (signature Object, Function)
        acceptInvite         :
          (signature Object, Function)
        rejectInvite         :
          (signature Object, Function)
        fetchPopularTopics   :
          (signature Object, Function)
        fetchPopularPosts    :
          (signature Object, Function)
        fetchPinnedMessages  :
          (signature Object, Function)
        fetchFollowedChannels:
          (signature Object, Function)
        fetchFollowedChannelCount:
          (signature Object, Function)
        searchTopics         :
          (signature Object, Function)
        fetchProfileFeed     :
          (signature Object, Function)
        fetchProfileFeedCount:
          (signature Object, Function)
        updateLastSeenTime   :
          (signature Object, Function)
        delete:
          (signature Object, Function)
        update:
          (signature Object, Function)
        create:
          (signature Object, Function)
        createChannelWithParticipants:
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
      static        : []

  JAccount     = require '../account'

  Validators   = require '../group/validators'
  { permit }   = require '../group/permissionset'

  { secureRequest, ensureGroupChannel,
    doRequest, permittedRequest } = require './helper'

  @generateChannelName = ({ groupSlug, apiChannelType, apiChannelName }) ->
    return "socialapi-\
    group-#{groupSlug}-\
    type-#{apiChannelType}-\
    name-#{apiChannelName}"

  @checkChannelParticipation = secureRequest
    fnName   : 'checkChannelParticipation'
    validate : ['name', 'type']


  # byId - fetch channel by id
  @byId = secureRequest
    fnName  : 'channelById'
    validate: ['id']

  # byName - fetch channel by name
  @byName = secureRequest
    fnName  : 'channelByName'
    validate: ['name']

  # update - update channel by name
  @update = secureRequest
    fnName  : 'updateChannel'
    validate: ['id']

  # create - create channel by name
  @create = secureRequest
    fnName  : 'createChannel'
    validate: ['name']

  # searchTopics - search topics for autocompletion
  @searchTopics          = secureRequest { fnName: 'searchTopics' }

  # fetchProfileFeed - lists all activities of an account
  # within a specified group
  @fetchProfileFeed      = secureRequest { fnName: 'fetchProfileFeed' }

  # fetchProfileFeedCount - fetches all activity count of an account
  # within a specified group
  @fetchProfileFeedCount = secureRequest { fnName: 'fetchProfileFeedCount' }

  # fetchPopularTopics - lists group specific popular topics
  # it can be daily, weekly, monthly
  @fetchPopularTopics    = secureRequest { fnName: 'fetchPopularTopics' }

  # fetchPopularPosts -  lists group specific popular posts
  # it can be daily, weekly, monthly
  @fetchPopularPosts     = secureRequest { fnName: 'fetchPopularPosts' }

  # fetchChannels - lists group's topic channels
  @fetchChannels         = secureRequest { fnName: 'fetchGroupChannels' }

  # fetchFollowedChannels - lists followed channels(topics) of an account
  @fetchFollowedChannels = secureRequest { fnName: 'fetchFollowedChannels' }

  # fetchFollowedChannelCount - fetch followed channel count of an account
  @fetchFollowedChannelCount = secureRequest { fnName: 'fetchFollowedChannelCount' }

  # updateLastSeenTime - updates user's channel presence data
  @updateLastSeenTime = secureRequest
    fnName  : 'updateLastSeenTime'
    validate: ['channelId']

  @listParticipants = secureRequest
    fnName  : 'listParticipants'
    validate: ['channelId']

  @addParticipants = secureRequest
    fnName  : 'addParticipants'
    validate: ['channelId']

  @removeParticipants = secureRequest
    fnName  : 'removeParticipants'
    validate: ['channelId']

  createChannelWithParticipantsHelper = (client, data, callback) ->
    doRequest 'createChannelWithParticipants', client, data, callback

  @createChannelWithParticipants = permit 'send private message',
    success: createChannelWithParticipantsHelper

  @leave = secure (client, data, callback) ->
    return callback new KodingError 'channel id is required for leaving a channel'  unless data.channelId

    { delegate } = client.connection
    data.accountIds = [ delegate.socialApiId ]  unless data.accountIds

    doRequest 'removeParticipants', client, data, callback

  @acceptInvite = secure (client, data, callback) ->
    return callback new KodingError 'channel id is required for accepting an invitation'  unless data.channelId

    { delegate } = client.connection
    data.accountId = delegate.socialApiId

    doRequest 'acceptInvite', client, data, callback

  @rejectInvite = secure (client, data, callback) ->
    return callback new KodingError 'channel id is required for rejecting an invitation'  unless data.channelId

    { delegate } = client.connection
    data.accountId = delegate.socialApiId

    doRequest 'rejectInvite', client, data, callback

  # fetchPinnedMessages - fetch user's pinned messages
  @fetchPinnedMessages = permittedRequest
    permissionName: 'pin posts'
    fnName        : 'fetchPinnedMessages'

  # followUser - a user follows a user
  @followUser = secure (client, options, callback) ->
    { connection:{ delegate } } = client
    return callback new KodingError 'Access denied'  if delegate.type isnt 'registered'
    unless options.followee
      return callback new KodingError 'Followee is not set'

    delegate.createSocialApiId (err, actorId) ->
      return callback err  if err
      options.followee.createSocialApiId (err, targetId) ->
        return callback err  if err
        { followUser, unfollowUser } = require './requests'
        data =
          accountId   : actorId
          creatorId   : targetId
        method = if options.unfollow then unfollowUser else followUser
        method data, callback

  { deleteChannel } = require './requests'

  @delete = permit
    advanced: [
      {
        permission: 'delete own posts'
        validateWith: require('./validators').own
      }
      {
        permission: 'delete posts'
        validateWith: require('../group/validators').any
      }
    ]
    success: (client, options, callback) ->

      return  callback new KodingError 'channel id not provided'  unless options.channelId?

      options.sessionToken = client.sessionToken

      return deleteChannel options, (err) ->

        return callback err  if err

        return callback null, options.channelId
