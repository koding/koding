{Model} = require 'bongo'

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


  # TODO not sure why we are creating session only for guest user
  @createSession = (callback) ->

    JUser = require './user'
    clientId = createId()

    JUser.fetchGuestUser (err, resp) =>

      return @emit 'error', err  if err

      unless resp
        console.error message = "Failed to create guest user :/ ~ This is critical!"
        return @emit 'error', {message}

      {account} = resp
      username  = JUser.createGuestUsername()
      session   = new JSession { clientId, username }

      session.save (err)->
        if err then callback err
        else callback null, { session, account }


  @createNewSession = (username, callback) ->
    clientId = createId()

    session = new JSession { clientId, username }
    session.save (err) ->
      return callback err  if err
      return callback null, session


  @fetchSession = (clientId, callback)->

    return @createSession callback  unless clientId

    @one {clientId}, (err, session)=>
      if err
        callback err
      else if session?
        callback null, { session }
      else
        @createSession callback


  @updateClientIP = (clientId, ipAddress, callback)->

    unless ipAddress
      return callback 'IP Address is missing'

    ipAddress = (ipAddress.split ',')[0]

    JSession.update {clientId: clientId}, {$set: clientIP: ipAddress}, (err)->
      callback err
