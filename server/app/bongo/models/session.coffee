{Model} = require 'bongo'

class JToken extends Model
  
  @setSchema
    token       : String
    expires     : Date
    authority   : String
    requester   : String

class JSession extends Model

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