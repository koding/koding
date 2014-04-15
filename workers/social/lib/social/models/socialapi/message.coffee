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

  Validators = require '../group/validators'
  {permit}   = require '../group/permissionset'

  @post = permit 'create posts',
    success: (client, data, callback)->
      SocialMessage.ensureGroupChannel client, (err, socialApiChannelId)->
        data.channelId = socialApiChannelId
        SocialMessage.doRequest 'postToChannel', client, data, callback

  @reply = permit 'create posts',
    success: (client, data, callback)->
      if not data.messageId or not data.body
        return callback message: "Request is not valid for adding a reply"
      SocialMessage.doRequest 'addReply', client, data, callback

  # todo add permission here
  @edit = secure (client, data, callback)->
    if not data.body or not data.id
      return callback { message: "Request is not valid for editing a message"}
    # check ownership of the account
    SocialMessage.canEdit client, data, (err, res)->
      return callback err if err
      return callback {message: "You can not edit this post"} unless res
      {editMessage} = require './requests'
      editMessage data, callback

  @delete = permit 'delete posts',
    success: (client, data, callback)->
      if not data.id
        return callback message: "Request is not valid for deleting a message"
      SocialMessage.doRequest 'deleteMessage', client, data, callback

  @like = permit 'like posts',
    success: (client, data, callback)->
      if not data.id
        return callback message: "Request is not valid for liking a message"
      SocialMessage.doRequest 'likeMessage', client, data, callback

  @unlike = permit 'like posts',
    success:  (client, data, callback)->
      if not data.id
        return callback message: "Request is not valid for unliking a message"
      SocialMessage.doRequest 'unlikeMessage', client, data, callback

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


  @ensureGroupChannel = (client, callback)->
    fetchGroup client, (err, group)->
      return callback err  if err
      group.createSocialApiChannelId (err, socialApiChannelId)->
        return callback err  if err
        callback null, socialApiChannelId

  # todo-- ask Chris about using validators.own
  # how to implement for this case
  @canEdit = (client, data, callback)->
    return callback {message: "Id is not set"} unless data.id
    {delegate} = client.connection
    req = id : data.id
    # get api id of the client
    delegate.createSocialApiId (err, socialApiId)->
      return callback err  if err
      # fetch the message
      {fetchMessage} = require './requests'
      fetchMessage req, (err, message)->
        return callback err  if err
        return callback { message: "Post is not found" }  unless message

        if message.accountId == socialApiId
          return callback null, yes
        console.log "fooo"
        delegate.canEditPost client, callback
