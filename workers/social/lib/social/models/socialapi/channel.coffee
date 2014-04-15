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
        listPinnedMessages:
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

  @fetchActivities = secure (client, options = {}, callback)->
    fetchGroup client, (err, group)->
      return callback err if err
      {connection:{delegate}} = client
      delegate.createSocialApiId (err, socialApiId)->
        return callback err if err

        options.channelId = options.id
        options.accountId = socialApiId
        options.groupName = group.slug

        {fetchChannelActivities} = require './requests'
        fetchChannelActivities options, callback

  @fetchPopularTopics = secure (client, options = {}, callback)->
    fetchGroup client, (err, group)->
      return callback err if err
      options.groupName = group.slug

      {fetchPopularTopics} = require './requests'
      fetchPopularTopics options, callback

  @fetchChannels = secure (client, options = {}, callback)->
    @fetchChannelReqeust 'fetchGroupChannels', client, options, callback

  @fetchFollowedChannels = secure (client, options = {}, callback)->
    @fetchChannelReqeust 'fetchFollowedChannels', client, options, callback

  @fetchChannelReqeust = (funcName, client, options, callback)->
    fetchGroup client, (err, group)->
      return callback err if err
      {connection:{delegate}} = client
      delegate.createSocialApiId (err, socialApiId)->
        return callback err if err

        options.groupName = group.slug
        options.accountId = socialApiId

        requests = require './requests'
        requests[funcName] options, callback

  @listPinnedMessages = permit 'pin posts',
    success:  (client, options, callback)->
      {connection:{delegate}, context} = client
      delegate.createSocialApiId (err, socialApiId)->
        return callback err if err
        options.accountId = socialApiId
        options.groupName = context.group
        {listPinnedMessages} = require './requests'
        listPinnedMessages options, callback

  @pinMessage = permit 'pin posts',
    success:  (client, data, callback)->
      {connection:{delegate}, context} = client
      delegate.createSocialApiId (err, socialApiId)->
        return callback err if err
        unless data.messageId
          return callback {message: "Message id is not set for pinning "}

        data.groupName = context.group
        data.accountId = socialApiId
        {pinMessage} = require './requests'
        pinMessage data, callback

  @unpinMessage = permit 'like posts',
    success:  (client, data, callback)->
      {connection:{delegate}, context} = client
      delegate.createSocialApiId (err, socialApiId)->
        return callback err if err
        unless data.messageId
          return callback {message: "Message id is not set for un-pinning "}

        data.groupName = context.group
        data.accountId = socialApiId
        {unpinMessage} = require './requests'
        unpinMessage data, callback

  @follow = secure (client, data, callback)->
    {connection:{delegate}, context} = client
    delegate.createSocialApiId (err, socialApiId)->
      return callback err if err
      unless data.channelId
        return callback {message: "Channel id is not set for following a topic"}

      data.groupName = context.group
      data.accountId = socialApiId
      {followTopic} = require './requests'
      followTopic data, callback

  @unfollow = secure (client, data, callback)->
    {connection:{delegate}, context} = client
    delegate.createSocialApiId (err, socialApiId)->
      return callback err if err
      unless data.channelId
        return callback {message: "Channel id is not set for topic unfollowing"}

      data.groupName = context.group
      data.accountId = socialApiId
      {unfollowTopic} = require './requests'
      unfollowTopic data, callback
