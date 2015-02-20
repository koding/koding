{Model} = require 'bongo'

class JToken extends Model

  @setSchema
    token       : String
    expires     : Date
    authority   : String
    requester   : String

module.exports = class JSession extends Model

  { v4: createId } = require 'node-uuid'

  @set
    indexes         :
      clientId      : 'unique'
      username      : 'descending'
      clientIP      : 'sparse'
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
      impersonating : Boolean
    sharedEvents    :
      instance      : []
      static        : []

  do ->
    JAccount  = require './account'

    JAccount.on 'UsernameChanged', ({ oldUsername, mustReauthenticate }) ->
      if mustReauthenticate
        console.log "JAccount.on 'UsernameChanged' JSession#remove", {
          oldUsername, mustReauthenticate }

        JSession.remove username: oldUsername, (err) ->
          console.error err  if err?


  safeGuestSessionName = (username)->

    if username is "guestuser"
      username = JUser.createGuestUsername()
      console.log "FIXME @gokmen --- overwritten with #{username}."

    return username


  @createSession = (callback) ->

    JUser = require './user'
    clientId = createId()

    JUser.fetchGuestUser (err, resp) =>

      if not resp
        console.error message = "Failed to create guest user :/ ~ This is critical!"
        return @emit 'error', {message}

      {account} = resp

      if err then @emit 'error', err
      else
        {nickname: username} = account.profile
        username = safeGuestSessionName username
        session  = new JSession { clientId, username }
        session.save (err)->
          if err
            callback err
          else
            callback null, { session, account }


  @fetchSession = (clientId, callback)->

    return @createSession callback  unless clientId

    @one {clientId}, (err, session)=>
      if err
        callback err
      else if session?
        callback null, { session }
      else
        @createSession callback


  @fetchGuestUserSession = (callback) ->

    JUser    = require './user'
    username = JUser.createGuestUsername()

    @one {username}, (err, session) ->
      return callback err  if err?
      return callback null, session  if session?

      clientId = createId()
      username = safeGuestSessionName username
      session  = new JSession { clientId, username }
      session.save (err)->
        return callback err  if err?
        callback null, session


  @updateClientIP = (clientId, ipAddress, callback)->

    unless ipAddress
      return callback 'IP Address is missing'

    ipAddress = (ipAddress.split ',')[0]

    JSession.update {clientId: clientId}, {$set: clientIP: ipAddress}, (err)->
      callback err
