{Module} = require 'jraphical'

module.exports = class JChatConversation extends Module

  {ObjectId, ObjectRef, secure} = require 'bongo'

  createId = require 'hat'

  KodingError = require '../../error'

  @share()

  @set
    sharedEvents    :
      static        : []
      instance      : ['updateInstance']
    sharedMethods   :
      static        : ['create']
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
      participants  :
        type        : [String]
        default     : -> []
      tags          : [ObjectRef]

  @create = secure (client, initialInvitees, callback)->
    {delegate} = client.connection

    conversation = new this {
      publicName  : createId()
      createdBy   : delegate.profile.nickname
    }
    
    conversation.save (err)->
      if err then callback err
      else
        callback null, conversation
        conversation.invite client, invitee  for invitee in initialInvitees

  invite: secure (client, invitee, callback)->
    {delegate} = client.connection
    {nickname} = delegate.profile

    delegateCanInvite = nickname? and
                        nickname in [@createdBy].concat @participants

    return callback new KodingError "Access denied!" unless delegateCanInvite

    @update {$addToSet: invitees: invitee}, (err)-> console.error err  if err?



