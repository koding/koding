{Module} = require 'jraphical'

module.exports = class JChatConversation extends Module

  {ObjectId, ObjectRef, secure} = require 'bongo'

  createId = require 'hat'

  KodingError = require '../../error'

  {uniq} = require 'underscore'

  @share()

  @set
    indexes         :
      publicName    : 'unique'
    sharedEvents    :
      static        : []
      instance      : ['updateInstance','notification']
    sharedMethods   :
      static        : ['create','fetch','fetchSome']
      instance      : ['invite']
    schema          :
      publicName    : String
      createdAt     :
        type        : Date
        default     : -> new Date
      createdBy     : String
      topic         : String
      description   : String
      avatar        : String
      group         : ObjectId
      invitees      :
        type        : [String]
        default     : -> []
      tags          : [ObjectRef]

  @fetch = secure (client, publicName, callback)->

    # Check if user logged in
    {delegate} = client.connection
    JAccount   = require '../account'
    unless delegate instanceof JAccount
      return callback new KodingError 'Access denied.'

    @one { publicName, invitees: delegate.profile.nickname }, callback

  @fetchSome = secure (client, options, callback)->

    # Check if user logged in
    {delegate} = client.connection
    JAccount   = require '../account'
    unless delegate instanceof JAccount
      return callback new KodingError 'Access denied.'

    [callback, options] = [options, callback] unless callback
    {nickname} = delegate.profile

    options  or= limit: 20
    selector   =
      $or: [
        {createdBy : nickname}
        {invitees  : nickname}
      ]

    @some selector, options, callback

  @create = secure (client, initialInvitees, callback)->

    # Check if user logged in
    {delegate} = client.connection
    JAccount   = require '../account'
    unless delegate instanceof JAccount
      return callback new KodingError 'Access denied.'

    {nickname} = delegate.profile

    initialInvitees.push nickname

    initialInvitees = uniq initialInvitees

    conversation = new this {
      publicName  : createId()
      createdBy   : nickname
    }

    @one { invitees: initialInvitees }, (err, conversation)->
      return callback err  if err
      if conversation
        conversation.invite client, invitee  for invitee in initialInvitees
        return callback err, conversation

      conversation = new JChatConversation
        publicName : createId()
        createdBy  : nickname

      conversation.save (err)->
        if err then callback err
        else
          callback null, conversation
          conversation.invite client, invitee  for invitee in initialInvitees

  invite: secure (client, invitee, callback)->
    {delegate} = client.connection
    {nickname} = delegate.profile

    delegateCanInvite = nickname? and nickname in @invitees

    return callback new KodingError "Access denied!" unless delegateCanInvite

    @update {$addToSet: invitees: invitee}, (err)=>
      return console.error err  if err?

      @emit 'notification', {
        event       : 'chatRequest'
        routingKey  : invitee
        contents    : { invitee, @publicName }
      }
