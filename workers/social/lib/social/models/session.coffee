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

  @set
    indexes         :
      clientId      : 'unique'
      username      : 'descending'
    schema          :
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
    sharedEvents    :
      instance      : [
        { name: 'updateInstance' }
      ]

  @cycleSession =(clientId, callback=(->)) ->
    @remove {clientId}, (err) =>
      if err
        callback err
      else
        @createSession (err, session, guest) ->
          if err
            callback err
          else
            callback null, guest, session.clientId

  @createSession =(callback) ->
    clientId = createId()
    JGuest.obtain null, clientId, (err, guest) =>
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
            callback null, session, guest

  @fetchSession =(clientId, callback)->
    selector = {clientId}
    @one selector, (err, session)=>
      if err
        callback err
      else if session?
        callback null, session
      else
        @createSession callback