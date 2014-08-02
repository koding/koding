Bongo          = require "bongo"
{Relationship} = require "jraphical"
request        = require 'request'
ApiError       = require './error'

{secure, daisy, dash, signature, Base} = Bongo
{uniq} = require 'underscore'


module.exports = class SocialMessage extends Base
  @share()

  @set
    permissions :
      # JPost related permissions
      'read posts'              : ['member', 'moderator']
      'create posts'            : ['member', 'moderator']
      'edit posts'              : ['moderator']
      'delete posts'            : ['moderator']
      'edit own posts'          : ['member', 'moderator']
      'delete own posts'        : ['member', 'moderator']
      'reply to posts'          : ['member', 'moderator']
      'like posts'              : ['member', 'moderator']
      'pin posts'               : ['member', 'moderator']
      'send private message'    : ['member', 'moderator']
      'list private messages'   : ['member', 'moderator']

      # JComment related permissions
      'edit comments'           : ['moderator']
      'edit own comments'       : ['moderator']

      # JTag related permissions
      'read tags'               :
        public                  : ['guest', 'member', 'moderator']
        private                 : ['member', 'moderator']
      'create tags'             : ['member', 'moderator']
      'freetag content'         : ['member', 'moderator']
      'browse content by tag'   : ['member', 'moderator']
      'edit tags'               : ['moderator']
      'delete tags'             : ['moderator']
      'edit own tags'           : ['moderator']
      'delete own tags'         : ['moderator']
      'assign system tag'       : ['moderator']
      'fetch system tag'        : ['moderator']
      'create system tag'       : ['moderator']
      'remove system tag'       : ['moderator']
      'create synonym tags'     : ['moderator']
      # 'delete system tag'     : ['moderator']

    # move permission from jpost to here
    # permissions :
    #   'send private message' : ['member', 'moderator']
    #   'list private messages' : ['member', 'moderator']
    sharedMethods :
      static   :
        byId   :
          (signature Object, Function)
        bySlug :
          (signature Object, Function)
        post   :
          (signature Object, Function)
        reply  :
          (signature Object, Function)
        edit   :
          (signature Object, Function)
        delete :
          (signature Object, Function)
        listReplies:
          (signature Object, Function)
        like   :
          (signature Object, Function)
        unlike :
          (signature Object, Function)
        listLikers:
          (signature Object, Function)
        sendPrivateMessage:
          (signature Object, Function)
        fetchPrivateMessages:
          (signature Object, Function)
        fetch  :
          (signature Object, Function)

    schema          :
      id               : Number
      body             : String
      accountId        : Number
      initialChannelId : Number
      createdAt        : Date
      updatedAt        : Date
      isFollowed       : Boolean

  JAccount = require '../account'

  Validators = require '../group/validators'
  {permit}   = require '../group/permissionset'

  { fetchGroup, secureRequest,
    doRequest, permittedRequest,
    ensureGroupChannel } = require "./helper"

  @post = permit 'create posts',
    success: (client, data, callback)->
      ensureGroupChannel client, (err, socialApiChannelId)->
        data.channelId = socialApiChannelId
        doRequest 'postToChannel', client, data, callback

  @reply = permit 'create posts',
    success: (client, data, callback)->
      if not data.messageId or not data.body
        return callback message: "Request is not valid for adding a reply"
      ensureGroupChannel client, (err, socialApiChannelId)->
        data.initialChannelId = socialApiChannelId
        doRequest 'addReply', client, data, callback

  # todo add permission here
  @edit = secure (client, data, callback)->
    if not data?.body or not data.id
      return callback { message: "Request is not valid for editing a message"}
    # check ownership of the account
    SocialMessage.canEdit client, data, (err, res)->
      return callback err if err
      return callback {message: "You can not edit this post"} unless res
      doRequest 'editMessage', client, data, callback


  @delete = secure (client, data, callback)->
    if not data?.id
      return callback { message: "Request is not valid for deleting a message" }

    # check ownership of the account
    SocialMessage.canDelete client, data, (err, res)->
      return callback err  if err
      return callback {message: "You can not delete this post"} unless res
      doRequest 'deleteMessage', client, data, callback


  # byId -get message by id
  @byId = secureRequest
    fnName  : 'messageById'
    validate: ["id"]

  # bySlug -get message by slug
  @bySlug = secureRequest
    fnName  : 'messageBySlug'
    validate: ["slug"]

  @listReplies = secureRequest
    fnName   : 'listReplies'
    validate : ['messageId']

  @like = permittedRequest
    permissionName : 'like posts'
    validate       : ['id']
    fnName         : 'likeMessage'

  @unlike = permittedRequest
    permissionName : 'like posts'
    validate       : ['id']
    fnName         : 'unlikeMessage'

  @listLikers = secureRequest
    fnName   : 'listLikers'
    validate : ['id']

  @fetchPrivateMessages = permittedRequest
    permissionName: 'list private messages'
    fnName        : 'fetchPrivateMessages'

  @fetch = permittedRequest
    permissionName: 'read posts'
    fnName        : 'fetchMessage'
    validate      : ['id']

  @sendPrivateMessage = permit 'send private message',
    success:  (client, data, callback)->
      unless data.body
        return callback message: "Message body should be set"

      if not data.recipients or data.recipients.length < 1
        return callback message: "You should have at least one recipient"
      doRequest 'sendPrivateMessage', client, data, callback

  # todo-- ask Chris about using validators.own
  # how to implement for this case
  @canEdit = (client, data, callback)->
    {delegate} = client.connection
    @checkMessagePermission client, data, delegate.canEditPost, callback

  @canDelete = (client, data, callback)->
    {delegate} = client.connection
    @checkMessagePermission client, data, delegate.canDeletePost, callback

  @checkMessagePermission = (client, data, fn, callback)->
    return callback {message: "Id is not set"} unless data.id
    {delegate} = client.connection
    # get api id of the client
    # TODO we are also calling this method inside do request
    delegate.createSocialApiId (err, socialApiId)=>
      return callback err  if err
      # fetch the message
      if delegate.checkFlag "super-admin"
        data.showExempt = true
      @byId client, data, (err, message)->
        return callback new ApiError err  if err
        return callback { message: "Post is not found" }  unless message?.message
        {message: {accountId}} = message
        if accountId is socialApiId
          return callback null, yes
        fn client, callback

