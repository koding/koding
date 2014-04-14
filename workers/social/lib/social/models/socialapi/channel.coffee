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
        fetchActivity     :
          (signature Object, Function)
        fetchChannels     :
          (signature Object, Function)
        fetchParticipants :
          (signature Object, Function)
        fetchPopularTopics:
          (signature Object, Function)
        listPinnedMessages:
          (signature Object, Function)
        pinMessage   :
          (signature Object, Function)
        unpinMessage :
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

  @fetchActivity = secure (client, options = {}, callback)->
    fetchGroup client, (err, group)->
      return callback err if err
      {connection:{delegate}} = client
      delegate.createSocialApiId (err, socialApiId)->
        return callback err if err

        data =
          channelId: options.id
          accountId: socialApiId
          groupName: group.slug

        {fetchChannelActivity} = require './requests'
        fetchChannelActivity data, callback

  @fetchPopularTopics = secure (client, options = {}, callback)->
    fetchGroup client, (err, group)->
      return callback err if err
      options.groupName = group.slug

      {fetchPopularTopics} = require './requests'
      fetchPopularTopics options, callback

  @fetchChannels = secure (client, options = {}, callback)->
    fetchGroup client, (err, group)->
      return callback err if err
      {connection:{delegate}} = client
      delegate.createSocialApiId (err, socialApiId)->
        return callback err if err

        data =
          groupName: group.slug
          accountId: socialApiId

        {fetchGroupChannels} = require './requests'
        fetchGroupChannels data, callback

  @listPinnedMessages = permit 'pin posts',
    success:  (client, data, callback)->
      {connection:{delegate}, context} = client
      delegate.createSocialApiId (err, socialApiId)->
        return callback err if err
        data.accountId = socialApiId
        data.groupName = context.group
        {listPinnedMessages} = require './requests'
        listPinnedMessages data, callback

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
