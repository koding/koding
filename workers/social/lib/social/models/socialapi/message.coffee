Bongo              = require 'bongo'
{ Relationship }   = require 'jraphical'
request            = require 'request'
ApiError           = require './error'
KodingError        = require '../../error'

{ secure, signature, Base } = Bongo
{ uniq, extend } = require 'underscore'



module.exports = class SocialMessage extends Base
  @share()

  @set
    classAttributes:
      # while sending XHR requests via bongo, we are batching those requests
      # but SocialMessage requests will not be batched
      bypassBatch   : yes

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
        initPrivateMessage:
          (signature Object, Function)
        sendPrivateMessage:
          (signature Object, Function)
        fetchPrivateMessages:
          (signature Object, Function)
        fetchPrivateMessageCount:
          (signature Object, Function)
        search :
          (signature Object, Function)
        fetch  :
          (signature Object, Function)
        fetchDataFromEmbedly: [
          (signature String, Object, Function)
          (signature [String], Object, Function)
        ]
        paymentSubscribe:
          (signature Object, Function)

    schema             :
      id               : Number
      body             : String
      accountId        : Number
      initialChannelId : Number
      createdAt        : Date
      updatedAt        : Date
      isFollowed       : Boolean

  JAccount = require '../account'

  Validators = require '../group/validators'
  { permit } = require '../group/permissionset'

  { secureRequest, ensureGroupChannel,
    doRequest, permittedRequest } = require './helper'

  @post = permit 'create posts',
    success: (client, data, callback) ->
      ensureGroupChannel client, (err, socialApiChannelId) ->
        data.channelId = socialApiChannelId unless data.channelId
        doRequest 'postToChannel', client, data, callback

  @reply = permit 'create posts',
    success: (client, data, callback) ->
      if not data.messageId or not data.body
        return callback new KodingError 'Request is not valid for adding a reply'
      ensureGroupChannel client, (err, socialApiChannelId) ->
        data.initialChannelId = socialApiChannelId
        doRequest 'addReply', client, data, callback

  # todo add permission here
  @edit = secure (client, data, callback) ->
    if not data?.body or not data.id
      return callback new KodingError 'Request is not valid for editing a message'
    # check ownership of the account
    SocialMessage.canEdit client, data, (err, res) ->
      return callback err if err
      return callback new KodingError 'You can not edit this post'  unless res
      doRequest 'editMessage', client, data, callback


  @delete = secure (client, data, callback) ->
    if not data?.id
      return callback new KodingError 'Request is not valid for deleting a message'

    # check ownership of the account
    SocialMessage.canDelete client, data, (err, res) ->
      return callback err  if err
      return callback new KodingError 'You can not delete this post'  unless res
      doRequest 'deleteMessage', client, data, callback


  # byId -get message by id
  @byId = secureRequest
    fnName  : 'messageById'
    validate: ['id']

  # bySlug -get message by slug
  @bySlug = secureRequest
    fnName  : 'messageBySlug'
    validate: ['slug']

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

  @fetchPrivateMessageCount = secureRequest
    permissionName: 'list private messages'
    fnName        : 'fetchPrivateMessageCount'

  @fetch = permittedRequest
    permissionName: 'read posts'
    fnName        : 'fetchMessage'
    validate      : ['id']

  initPrivateMessageHelper = (client, data, callback) ->

    if not data.recipients or data.recipients.length < 1
      return callback new KodingError 'You should have at least one recipient'

    doRequest 'initPrivateMessage', client, data, callback

  sendPrivateMessageHelper = (client, data, callback) ->
    unless data.body
      return callback new KodingError 'Message body should be set'

    unless data.channelId
      return callback new KodingError 'Conversation is not defined'

    doRequest 'sendPrivateMessage', client, data, callback

  @initPrivateMessage = permit 'send private message',
    success: initPrivateMessageHelper

  @sendPrivateMessage = permit 'send private message',
    success: sendPrivateMessageHelper

  # searchChats - browse chats depending on purpose/username fields
  @search  = secureRequest { fnName: 'searchChats' }

  # todo-- ask Chris about using validators.own
  # how to implement for this case
  @canEdit = (client, data, callback) ->
    { delegate } = client.connection
    @checkMessagePermission client, data, delegate.canEditPost, callback

  @canDelete = (client, data, callback) ->
    { delegate } = client.connection
    @checkMessagePermission client, data, delegate.canDeletePost, callback

  @checkMessagePermission = (client, data, fn, callback) ->
    return callback new KodingError 'Id is not set'  unless data.id
    { delegate } = client.connection
    # get api id of the client
    # TODO we are also calling this method inside do request
    delegate.createSocialApiId (err, socialApiId) =>
      return callback err  if err
      # fetch the message
      if delegate.checkFlag 'super-admin'
        data.showExempt = true
      @byId client, data, (err, message) ->
        return callback new ApiError err  if err
        return callback new KodingError 'Post is not found'  unless message?.message
        { message: { accountId } } = message
        if accountId is socialApiId
          return callback null, yes
        fn client, callback


  cachedEmbedlyResult = {}

  @fetchDataFromEmbedly = (urls, options, callback) ->

    if result = cachedEmbedlyResult[urls]
      return callback null, result

    urls = [urls]  unless Array.isArray urls

    Embedly    = require 'embedly'
    { apiKey } = KONFIG.embedly

    new Embedly { key: apiKey }, (err, api) ->

      return callback err  if err

      options    = extend options,
        urls     : urls
        maxWidth : 600
        videosrc : yes
        autoplay : yes
        luxe     : 1

      api.extract options, (err, result) ->

        if err or result[0]?.error_code
          return callback err, result

        cachedEmbedlyResult[urls] = result
        callback err, result


  @paymentSubscribe = secure (client, options, callback) ->
    doRequest 'paymentSubscribe', client, options, callback
