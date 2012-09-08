{Model} = require 'bongo'

module.exports = class JSession extends Model

  JToken = require './token'

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