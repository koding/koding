class JToken extends bongo.Model
  
  @setSchema
    token       : String
    expires     : Date
    authority   : String
    requester   : String

class JSession extends bongo.Model

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
    tokens        : [JToken]