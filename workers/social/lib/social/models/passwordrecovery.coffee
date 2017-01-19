uuid          = require 'uuid'
async         = require 'async'
jraphical     = require 'jraphical'
emailsanitize = require './user/emailsanitize'
KodingError   = require '../error'

module.exports = class JPasswordRecovery extends jraphical.Module
  # TODO - Refactor this file, now it is not only for password recovery
  # but also for email verification
  { secure, signature }        = require 'bongo'

  JUser                        = require './user'
  Tracker                      = require './tracker'
  dateFormat                   = require 'dateformat'


  UNKNOWN_ERROR = { message: 'Error occurred. Please try again.' }

  @share()

  @set
    sharedEvents  :
      static      : []
      instance    : []
    sharedMethods :
      static:
        validate:
          (signature String, Function)
        recoverPassword:
          (signature String, Function)
        resendVerification:
          (signature String, Function)
        resetPassword:
          (signature String, String, Function)
        fetchRegistrationDetails:
          (signature String, Function)
    indexes       :
      token       : 'unique'
    schema        :
      email       :
        type      : String
        set       : (email) -> email.trim()
      username    : String
      token       : String
      redeemedAt  : Date
      expiresAt   : Date
      expires     : Boolean
      status      :
        type      : String
        enum      : ['invalid status code'
                    [
                      'active'
                      'expired'
                      'redeemed'
                      'invalidated'
                    ]]
      requestedAt :
        type      : Date
        default   : -> new Date

  @expiryPeriod = 1000 * 60 * 90 # 90 min

  @getEmailSubject = ({ resetPassword }) ->
    if resetPassword then Tracker.types.REQUEST_NEW_PASSWORD
    else Tracker.types.REQUEST_EMAIL_CHANGE

  @recoverPassword = secure (client, usernameOrEmail, callback) ->
    JUser = require './user'
    if JUser.validateAt 'email', usernameOrEmail
      @recoverPasswordByEmail { email: usernameOrEmail, resetPassword:yes }, callback
    # Disable it until we find a solution ~ GG
    # else if JUser.validateAt 'username', usernameOrEmail
    #   @recoverPasswordByUsername {username: usernameOrEmail, resetPassword:yes}, callback
    else callback new KodingError 'Invalid input.'

  @resendVerification = secure (client, usernameOrEmail, callback) ->
    JUser = require './user'
    if JUser.validateAt 'email', usernameOrEmail
      @recoverPasswordByEmail { email: usernameOrEmail, resetPassword:no, verb:'Verify' }, callback
    else if JUser.validateAt 'username', usernameOrEmail
      @recoverPasswordByUsername { username: usernameOrEmail, resetPassword:no, verb:'Verify' }, callback
    else callback new KodingError 'Invalid input.'

  @recoverPasswordByUsername = (options, callback) ->
    JUser = require './user'
    { username } = options

    JUser.one { username }, (err, user) =>
      unless user
        return callback new KodingError 'Unknown username'

      options.email = user.getAt('email')
      @create options, callback

  @recoverPasswordByEmail = (options, callback) ->
    JUser = require './user'
    { email, group, mode } = options

    sanitizedEmail = emailsanitize email, { excludeDots: yes, excludePlus: yes }

    JUser.count { sanitizedEmail }, (err, num) =>
      unless num
        return callback null # pretend like everything went fine.

      options.resetPassword = yes
      options.verb = 'Team/Reset'
      options.queryParams = { mode }  if mode
      @create options, callback

  @create = (options, callback) ->
    JUser = require './user'
    token = uuid.v4()

    { email, sanitizedEmail, verb }      = options
    { expiryPeriod, group, queryParams } = options

    email = email.trim()
    sanitizedEmail or= emailsanitize email, { excludeDots: yes, excludePlus: yes }

    options.resetPassword ?= no

    expiryPeriod ?= @expiryPeriod

    verb ?= 'Reset'

    { host, protocol } = require '../config.email'

    JUser.one { sanitizedEmail }, (err, user) =>
      if err
        callback err
      else unless user
        callback new KodingError 'User not found'
      else
        username    = user.getAt('username')
        certificate = new JPasswordRecovery {
          email
          token
          expiryPeriod
          username
          status    : 'active'
        }
        certificate.save (err) =>
          if err
            callback err
          else
            host = "#{group}.#{host}"  if group and group isnt 'koding'
            if queryParams
              pairs = ("#{name}=#{encodeURIComponent value}" for name, value of queryParams)
              query = "?#{pairs.join '&'}"
            tokenUrl = "#{protocol}//#{host}/#{verb}/#{encodeURIComponent token}#{query ? ''}"

            messageOptions =
              url           : tokenUrl
              resetPassword : options.resetPassword
              requestedAt   : certificate.getAt('requestedAt')

            Tracker = require './tracker'
            Tracker.identify username, { email }

            Tracker.track username, {
              to         : email
              subject    : @getEmailSubject messageOptions
            }, { tokenUrl, firstName:username }

            callback null


  @validate = (token, callback) ->
    @one { token }, (err, certificate) ->
      return callback err  if err

      if not certificate or (certificate?.status is 'invalidated')
        return callback { message: 'Invalid token.', short: 'invalid_token' }

      if certificate.status is 'redeemed'
        return callback { message: 'Already redeemed', short: 'redeemed_token' }

      if certificate.status is 'expired'
        return callback { message: 'The token has expired.', short: 'expired_token' }

      if certificate.getAt('expiresAt') < new Date
        certificate.expire (err) ->
          return callback err  if err
          return callback { message: 'The token has expired.', short: 'expired_token' }

      JUser = require './user'
      JUser.one { email:certificate.email }, (err, user) ->
        return callback UNKNOWN_ERROR  if err or not user
        user.confirmEmail (err) ->
          return callback UNKNOWN_ERROR  if err
          certificate.update { $set: { status: 'redeemed' } }, callback

  @invalidate = (query, callback) ->
    query.status = 'active'
    @update query, { $set: { status: 'invalidated' } }, callback


  @resetPassword = (token, newPassword, callback) ->

    user        = null
    username    = null
    certificate = null

    queue = [

      (next) ->
        # checking if token is valid
        JPasswordRecovery.one { token }, (err, certificate_) ->
          return next err  if err
          return next new KodingError 'Invalid token.'  unless certificate_

          { status, expiresAt } = certificate = certificate_

          if (status isnt 'active') or (expiresAt? and expiresAt < new Date)
            return next new KodingError '''
              This password recovery certificate cannot be redeemed.
              '''
          next()

      (next) ->
        # checking if user exists
        { username } = certificate

        JUser.one { username }, (err, user_) ->
          return next err  if err
          return next new KodingError 'Unknown user!'  unless user_
          user = user_
          next()

      (next) ->
        # redeeming token
        certificate.redeem next

      (next) ->
        # changing user's password to new one
        user.changePassword newPassword, next

      (next) ->
        # kill user sessions
        user.killSessions {}, (err) ->
          next()

      (next) ->
        # invalidating other active tokens
        JPasswordRecovery.invalidate { username }, next

    ]

    async.series queue, (err) ->
      return callback err  if err
      callback null, username


  @resetPassword$ = secure (client, token, newPassword, callback) ->
    JUser = require './user'
    { delegate } = client.connection
    unless delegate.type is 'unregistered'
      callback { message: 'You are already logged in!' }
    else
      @resetPassword token, newPassword, callback

  @fetchRegistrationDetails = (token, callback) ->
    JAccount = require './account'

    @one { token, status: 'active' }, (err, certificate) ->
      return callback err  if err
      return callback { message: 'Unrecognized token!' }  unless certificate

      { email, username } = certificate

      JAccount.one { 'profile.nickname': username }, (err, account) ->
        return callback err  if err
        return callback { message: 'Unrecognized token!' }  unless account

        { firstName, lastName } = account.profile

        callback null, { firstName, lastName, email }

  expire: (callback) -> @update { $set: { status: 'expired' } }, callback

  redeem: (callback) ->
    @update { $set: { status: 'redeemed' } }, callback
