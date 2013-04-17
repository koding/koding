{Module} = require 'jraphical'

module.exports = class JChatConversation extends Module

  {ObjectId, ObjectRef} = require 'bongo'

  @share()

  @set
    sharedEvents  :
      static      : []
      instance    : []
    sharedMethods :
      static      : ['create']
      instance    : []
    schema        :
      publicName  : String
      createdAt   :
        type      : Date
        default   : -> new Date
      createdBy   : String
      topic       : String
      description : String
      avatar      : String
      group       : ObjectId
      members     : [String]
      tags        : [ObjectRef]

  @create = ->
    console.log 'this is a stub'