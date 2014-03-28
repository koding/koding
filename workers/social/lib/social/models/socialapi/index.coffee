Bongo          = require "bongo"
{Relationship} = require "jraphical"
request        = require 'request'

{secure, daisy, dash, signature, Base} = Bongo
{uniq} = require 'underscore'


module.exports = class Social extends Base
  @share()

  @set
    sharedMethods :
      static      :
        fetchGroupActivity :
          (signature Object, Function)
        editMessage   :
          (signature Object, Function)
        addReply      :
          (signature Object, Function)
        deleteMessage :
          (signature Object, Function)
        likeMessage   :
          (signature Object, Function)
        unlikeMessage :
          (signature Object, Function)
        postToChannel :
          (signature Object, Function)
    schema          :
      id               : Number
      body             : String
      accountId        : Number
      initialChannelId : Number
      createdAt        : Date
      updatedAt        : Date

  JAccount = require '../account'

  @fetchGroup: (client, callback)->
    groupName = client.context.group or "koding"
    JGroup = require '../group'
    JGroup.one slug : groupName, (err, group)=>
      return callback err  if err
      return callback {error: "Group not found"}  unless group

      {delegate} = client.connection
      return callback {error: "Request not valid"} unless delegate
      group.canReadGroupActivity client, (err, res)->
        if err then return callback {error: "Not allowed to open this group"}
        else callback null, group


  @fetchGroupActivity = secure (client, options = {}, callback)->
    {connection:{delegate}} = client
    delegate.createSocialApiId (err, socialApiId)=>
      return callback err if err
      @fetchGroup client, (err, group)=>
        return callback err  if err
        group.createSocialApiChannelId (err, socialApiChannelId)->
          return callback err  if err
          {fetchChannelAtivity} = require './requests'

          data =
            channelId: socialApiChannelId
            accountId: socialApiId


          fetchChannelAtivity data, (err, activities)->
            callback err, activities

  @postToChannel = secure (client, data, callback)->
    {connection:{delegate}} = client
    delegate.createSocialApiId (err, socialApiId)=>
      return callback err if err
      @fetchGroup client, (err, group)=>
        return callback err  if err
        group.createSocialApiChannelId (err, socialApiChannelId)->
          return callback err  if err
          {postToChannel} = require './requests'

          data.channelId = socialApiChannelId
          data.accountId = socialApiId

          postToChannel data, (err, activities)->
            callback err, activities

  # Id # Body # Type # AccountId
  # InitialChannelId # CreatedAt
  # UpdatedAt

  # todo add permission here
  @editMessage = secure (client, data, callback)->
    if not data.body or not data.id
      return callback { message: "Request is not valid for editing a message"}
    {editMessage} = require './requests'
    editMessage data, (err, activities)->
      callback err, activities

  # todo add permission here
  @deleteMessage = secure (client, data, callback)->
    if not data.id
      return callback { message: "Request is not valid for deleting a message"}
    {deleteMessage} = require './requests'
    deleteMessage data, (err, activities)->
      callback err, activities

  # todo add permission here
  @likeMessage = secure (client, data, callback)->
    {connection:{delegate}} = client
    delegate.createSocialApiId (err, socialApiId)=>
      return callback err if err
      if not data.id
        return callback { message: "Request is not valid for liking a message"}
      data.accountId = socialApiId
      {likeMessage} = require './requests'
      likeMessage data, (err, result)->
        callback err, result

  # todo add permission here
  @unlikeMessage = secure (client, data, callback)->
    {connection:{delegate}} = client
    delegate.createSocialApiId (err, socialApiId)=>
      return callback err if err
      if not data.id
        return callback { message: "Request is not valid for unliking a message"}
      data.accountId = socialApiId
      {unlikeMessage} = require './requests'
      unlikeMessage data, (err, result)->
        callback err, result

  @addReply = secure (client, data, callback)->
    {connection:{delegate}} = client
    delegate.createSocialApiId (err, socialApiId)=>
      return callback err if err
      if not data.messageId or not data.body
        return callback { message: "Request is not valid for add a reply to the message" }
      data.accountId = socialApiId
      (require './requests').addReply data, (err, result)->
        callback err, result
