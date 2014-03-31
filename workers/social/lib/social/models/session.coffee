{Model} = require 'bongo'

class JToken extends Model

  @setSchema
    token       : String
    expires     : Date
    authority   : String
    requester   : String

module.exports = class JSession extends Model

  { v4: createId } = require 'node-uuid'

  # JUser    = require './guest'

  @set
    indexes         :
      clientId      : 'unique'
      username      : 'descending'
    schema          :
      clientId      : String
      clientIP      : String
      username      : String
      guestId       : Number
      terminalId    : String
      sessionBegan  :
        type        : Date
        default     : -> new Date
      lastAccess    :
        type        : Date
        get         : -> new Date
      foreignAuth   :
        github      : Object
        odesk       : Object
        facebook    : Object
        linkedin    : Object
      foreignAuthType : String
    sharedEvents    :
      instance      : []
      static        : []

  do ->
    JAccount  = require './account'

    JAccount.on 'UsernameChanged', ({ oldUsername, mustReauthenticate }) ->
      if mustReauthenticate
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
    JUser.createTemporaryUser (err, resp) =>

      if not resp
        console.error message = "Failed to create guest user :/ ~ This is critical!"
        return @emit 'error', {message}

      {account} = resp

      if err then @emit 'error', err
      else
        {nickname: username} = account.profile
        session = new JSession { clientId, username }
        session.save (err)->
          if err
            callback err
          else
            callback null, session, account

  @fetchSession =(clientId, callback)->
    # if clientId is undefined or null
    return @createSession callback  unless clientId

    selector = {clientId}
    @one selector, (err, session)=>
      if err
        callback err
      else if session?
        callback null, session
      else
        @createSession callback

  @updateClientIP = (clientId, ipAddress, callback)->
    JSession.update {clientId: clientId}, {$set: clientIP: ipAddress}, (err)->
      callback err
