{Model} = require 'bongo'

class JToken extends Model

  @setSchema
    token       : String
    expires     : Date
    authority   : String
    requester   : String

module.exports = class JSession extends Model

  createId = require 'hat'

  # JUser    = require './guest'

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

  do ->
    JAccount  = require './account'

    JAccount.on 'UsernameChanged', ({oldUsername}) ->
      JSession.remove username: oldUsername, (err) ->
        console.error err  if err?

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
    JUser = require './user'
    clientId = createId()
    JUser.createTemporaryUser (err, account) =>
      if err then @emit 'error', err
      else
        {nickname: username} = account.profile
        session = new JSession { clientId, username }
        session.save (err)->
          if err
            callback err
          else
            callback null, session, account

    # JGuest.obtain null, clientId, (err, guest) =>
    #   if err
    #     @emit 'error', err
    #   else
    #     {guestId} = guest
    #     session = new JSession {
    #       clientId
    #       guestId
    #     }
    #     session.save (err)->
    #       if err
    #         callback err
    #       else
    #         callback null, session, guest

  @fetchSession =(clientId, callback)->
    selector = {clientId}
    @one selector, (err, session)=>
      if err
        callback err
      else if session?
        callback null, session
      else
        @createSession callback