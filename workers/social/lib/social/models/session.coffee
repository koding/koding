{Model} = require 'bongo'

class JToken extends Model
  
  @setSchema
    token       : String
    expires     : Date
    authority   : String
    requester   : String

module.exports = class JSession extends Model

  createId = require 'hat'

  JGuest = require './guest'

  @setSchema
    clientId      : String
    username      : String
    guestId       : Number
    terminalId    : String
    sessionBegan  :
      type        : Date
      default     : -> new Date
    lastAccess    :
      type        : Date
      get         : -> new Date
    nonce         : String
    nonces        : [String]
    tokens        : [JToken]
  
   
  @createSession =(callback)->
    clientId = createId()
    guest = new JGuest {clientId}
    guest.save (err, docs)=>
      if err
        @emit 'error', err
      else
        {guestId} = guest
        session = new JSession {
          clientId
          guestId
        }
        session.save (err)->
          if err
            callback err
          else
            callback null, session

  @fetchSession =(clientId, callback)->
    @one {clientId}, (err, session)=>
      if err
        callback err
      else if session
        callback null, session
      else
        @createSession (err, session)->
          if err
            callback err
          else
            callback null, session