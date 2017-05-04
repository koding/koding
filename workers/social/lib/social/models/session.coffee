uuid = require 'uuid'
KodingError = require '../error'
{ Model, secure, signature } = require 'bongo'

module.exports = class JSession extends Model

  @share()

  @set
    indexes             :
      clientId          : 'unique'
      otaToken          : 'sparse' # unique is also required
      username          : 'descending'
      clientIP          : 'sparse'
    schema              :
      clientId          : String
      clientIP          : String
      username          : String
      otaToken          : String
      groupName         :
        type            : String
        default         : -> 'koding'
      guestId           : Number
      terminalId        : String
      sessionBegan      :
        type            : Date
        default         : -> new Date
      guestSessionBegan : Date
      lastAccess        :
        type            : Date
        default         : -> new Date
      foreignAuth       :
        gitlab          : Object
        github          : Object
        facebook        : Object
        linkedin        : Object
      returnUrl         : String
      foreignAuthType   : String
      impersonating     : Boolean
      # data holds arbitary transitive session based info, not necessarily
      # should be used. There won't be any kind of index on this field.
      sessionData       : Object
    sharedEvents        :
      instance          : []
      static            : []
    sharedMethods       :
      static            :
        activeSession   :
          (signature Function)
      instance          :
        remove          :
          (signature Function)

  do ->
    JAccount  = require './account'

    JAccount.on 'UsernameChanged', ({ oldUsername, mustReauthenticate }) ->
      if mustReauthenticate
        console.log "JAccount.on 'UsernameChanged' JSession#remove", {
          oldUsername, mustReauthenticate }

        JSession.remove { username: oldUsername }, (err) ->
          console.error err  if err?


  @activeSession = secure (client, callback) ->
    @one { clientId: client.sessionToken }, callback


  # TODO not sure why we are creating session only for guest user
  @createSession = (options, callback) ->

    [ options, callback ] = [ callback, options ]  unless callback
    { group } = options ?= {}
    group    ?= 'koding'

    JUser    = require './user'
    clientId = uuid.v4()

    JUser.fetchGuestUser (err, resp) =>

      return @emit 'error', err  if err

      unless resp
        console.error message = 'Failed to create guest user :/ ~ This is critical!'
        return @emit 'error', { message }

      { account } = resp

      sessionOptions = {
        username          : JUser.createGuestUsername()
        groupName         : group
        guestSessionBegan : new Date()
        clientId
      }

      @createNewSession sessionOptions, (err, session) ->
        if err then callback err
        else callback null, { session, account }


  @createNewSession = (data, callback) ->

    data.clientId ?= uuid.v4()

    session = new JSession data
    session.save (err) ->
      return callback err  if err
      return callback null, session


  # fetchSession tries to fetch session with given clientId, if client id is not
  # set, it tries to create a new session, if session doesnt exist in db with
  # given clientId, it creates a new one
  #
  # ps: i didnt write this function, just documenting it ~ CS
  @fetchSession = (options, callback) ->

    { clientId, group } = options

    return @createSession { group }, callback  unless clientId

    @one { clientId }, (err, session) =>
      if err
        callback err
      else if session
        callback null, { session }
      else
        @createSession { group }, callback

  # fetchSessionByData tries to fetch a session for given data, if
  # doesnt exist creates a new one with given data
  #
  # Please use this function with care, check if the given parameters have an
  # index in mongo
  #
  # i dont like this function name but following the same principle with
  # fetchSession ~ CS
  @fetchSessionByData = (query, data, callback) ->
    [callback, data] = [data, callback]  unless callback
    data = query  unless data
    @one query, (err, session) =>
      return callback err  if err
      return callback null, session  if session?
      @createNewSession data, callback


  @updateClientIP = (clientId, ipAddress, callback) ->

    unless ipAddress
      return callback 'IP Address is missing'

    ipAddress = (ipAddress.split ',')[0]

    @update { clientId: clientId }, { $set: { clientIP: ipAddress } }, (err) ->
      callback err


  @fetchOAuthInfo = (clientId, callback) ->

    @one { clientId: clientId }, (err, session) ->
      return callback err   if err
      return callback null  unless session

      { foreignAuth, foreignAuthType } = session
      if foreignAuth and foreignAuthType
        callback null, { foreignAuth, foreignAuthType, session }
      else
        callback null # WARNING: don't assume it's an error if there's no foreignAuth


  @clearOauthInfo = (session, callback) ->
    session.update { $unset: { foreignAuth:1, foreignAuthType:1 } }, callback


  remove$: secure (client, callback) ->

    username = client.connection?.delegate?.profile?.nickname

    # check if requester is the owner of the current session
    unless @username is username
      return callback new KodingError 'Access denied'

    @remove callback


  isGuestSession: ->
    !!(@getAt('guestSessionBegan') or /^guest\-/.test @getAt('username'))
