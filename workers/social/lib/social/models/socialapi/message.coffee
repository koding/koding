Bongo          = require "bongo"
{Relationship} = require "jraphical"
request        = require 'request'

{secure, daisy, dash, signature, Base} = Bongo
{uniq} = require 'underscore'


module.exports = class SocialMessage extends Base
  @share()

  @set
    sharedMethods :
      static   :
        post   :
          (signature Object, Function)
        reply  :
          (signature Object, Function)
        edit   :
          (signature Object, Function)
        delete :
          (signature Object, Function)
        like   :
          (signature Object, Function)
        unlike :
          (signature Object, Function)

    schema          :
      id               : Number
      body             : String
      accountId        : Number
      initialChannelId : Number
      createdAt        : Date
      updatedAt        : Date

  JAccount = require '../account'

  {fetchGroup} = require "./helper"

  @ensureGroupChannel = (client, callback)->
    fetchGroup client, (err, group)->
      return callback err  if err
      group.createSocialApiChannelId (err, socialApiChannelId)->
        return callback err  if err
        callback null, socialApiChannelId

  @post = secure (client, data, callback)->
    {connection:{delegate}} = client
    delegate.createSocialApiId (err, socialApiId)->
      return callback err if err
      SocialMessage.ensureGroupChannel client, (err, socialApiChannelId)->
        return callback err  if err
        {postToChannel} = require './requests'

        data.channelId = socialApiChannelId
        data.accountId = socialApiId

        postToChannel data, (err, activities)->
          callback err, activities

  @reply = secure (client, data, callback)->
    {connection:{delegate}} = client
    delegate.createSocialApiId (err, socialApiId)=>
      return callback err if err
      if not data.messageId or not data.body
        return callback { message: "Request is not valid for add a reply to the message" }
      data.accountId = socialApiId
      (require './requests').addReply data, (err, result)->
        callback err, result

  # todo add permission here
  @edit = secure (client, data, callback)->
    if not data.body or not data.id
      return callback { message: "Request is not valid for editing a message"}
    {editMessage} = require './requests'
    editMessage data, (err, activities)->
      callback err, activities

  # todo add permission here
  @delete = secure (client, data, callback)->
    if not data.id
      return callback { message: "Request is not valid for deleting a message"}
    {deleteMessage} = require './requests'
    deleteMessage data, (err, activities)->
      callback err, activities

  # todo add permission here
  @like = secure (client, data, callback)->
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
  @unlike = secure (client, data, callback)->
    {connection:{delegate}} = client
    delegate.createSocialApiId (err, socialApiId)=>
      return callback err if err
      if not data.id
        return callback { message: "Request is not valid for unliking a message"}
      data.accountId = socialApiId
      {unlikeMessage} = require './requests'
      unlikeMessage data, (err, result)->
        callback err, result
