jraphical = require 'jraphical'

module.exports = class JPasswordRecovery extends jraphical.Module
  # TODO - Refactor this file, now it is not only for password recovery
  # but also for email verification
  {secure, signature} = require 'bongo'

  dateFormat  = require 'dateformat'
  createId    = require 'hat'

  KodingError = require '../error'
  JUser       = require './user'

  @share()

  @set
    sharedMethods:
      static:
        validate:
          (signature String, Function)
        recoverPassword:
          (signature String, Function)
        resetPassword:
          (signature String, String, Function)
        fetchRegistrationDetails:
          (signature String, Function)
    indexes       :
      token       : 'unique'
    schema        :
      email       : String
      username    : String
      token       : String
      redeemedAt  : Date
      expiresAt   :
        type      : Date
        default   : -> new Date Date.now() + 1000 * 60 * 30 # thirty minutes from now
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

  @getPasswordRecoveryEmail =-> 'hello@koding.com'

  @getEmailSubject = ({resetPassword})-> switch
    when resetPassword
      "Instructions to reset your password"
    else
      "Instructions to confirm your email"

  @getEmailDateFormat = -> 'fullDate'

  @getEmailMessage = ({requestedAt, url, resetPassword})->
    # TODO DRY this
    verb = if resetPassword then "reset" else "confirm"
    obj = if resetPassword then "password" else "email"
    """
    At #{dateFormat requestedAt, 'shortTime'} on #{dateFormat requestedAt, 'shortDate'}, you requested to #{verb} your #{obj}.

    This one-time token will allow you to #{verb} your #{obj}.  This token will self-destruct 30 minutes after it is issued.

    #{url}
    """

  @recoverPassword = secure (client, usernameOrEmail, callback)->
    JUser = require './user'
    if JUser.validateAt 'email', usernameOrEmail
      @recoverPasswordByEmail client, usernameOrEmail, callback
    else if JUser.validateAt 'username', usernameOrEmail
      @recoverPasswordByUsername client, usernameOrEmail, callback
    else callback new KodingError 'Invalid input.'

  @recoverPasswordByUsername = (client, username, callback)->
    JUser = require './user'
    {delegate} = client.connection
    JUser.one {username}, (err, user)=>
      unless user then callback new KodingError "Unknown username"
      else @create client, {email: user.getAt('email')}, callback

  @recoverPasswordByEmail = secure (client, email, callback)->
    JUser = require './user'
    {delegate} = client.connection
    JUser.count {email}, (err, num)=>
      unless num then callback null # pretend like everything went fine.
      else @create client, {email}, callback

  @create = (client, options, callback)->
    JUser = require './user'
    token = createId()
    {email, verb} = options

    verb ?= "Reset"

    defaultExpiresAt = new Date Date.now() + 1000 * 60 * 30 # 30 minutes

    {host, protocol} = require '../config.email'
    messageOptions =
      url : "#{protocol}//#{host}/#{verb}/#{encodeURIComponent token}"

    JUser.one {email}, (err, user)=>
      if err
        callback err
      else
        certificate = new JPasswordRecovery {
          email
          token
          expiresAt : defaultExpiresAt
          username  : user.getAt('username')
          status    : 'active'
        }
        certificate.save (err)=>
          if err
            callback err
          else
            messageOptions.requestedAt = certificate.getAt('requestedAt')

            messageOptions.resetPassword = no# if user.passwordStatus is 'needs set' then yes else no
            JMail = require './email'
            email = new JMail
              from      : @getPasswordRecoveryEmail()
              email     : email
              subject   : @getEmailSubject messageOptions
              content   : @getEmailMessage messageOptions
              force     : yes

            email.save callback

  @validate = secure ({connection:{delegate}}, token, callback)->
    @one {token, status: 'active'}, (err, certificate)->
      if err
        callback err
      else unless certificate
        callback new KodingError 'Invalid token.'
      else if certificate.getAt('expiresAt') < new Date
        certificate.expire (err)->
          if err
            callback err
          else
            callback new KodingError 'The token has expired.'
      else
        JUser = require './user'
        JUser.one {email:certificate.email}, (err, user)->
          return callback new Error "Error occured. Please try again." if err or not user
          user.confirmEmail (err)->
            return callback new Error "Error occured. Please try again." if err
            callback null, yes

  @invalidate =(query, callback)->
    query.status = 'active'
    @update query, {$set: status: 'invalidated'}, callback

  @resetPassword = secure (client, token, newPassword, callback)->
    JUser = require './user'
    {delegate} = client.connection
    unless delegate.type is 'unregistered'
      callback new KodingError 'You are already logged in!'
    else
      @one {token}, (err, certificate)->
        if err
          callback err
        else unless certificate
          callback new KodingError 'Invalid token.'
        else if certificate.getAt('status') isnt 'active' or
                certificate.getAt('expiresAt') < new Date
          callback new KodingError """
            This password recovery certificate cannot be redeemed.
            """
        else
          {username} = certificate
          JUser.one {username}, (err, user)->
            if err or !user
              callback err or new KodingError "Unknown user!"
            else certificate.redeem (err)->
              if err
                callback err
              else
                user.changePassword newPassword, (err)->
                  if err
                    callback err
                  else
                    JPasswordRecovery.invalidate {username}, (err)->
                      return callback new Error "Error occured. Please try again." if err
                      user.confirmEmail (err)->
                        return callback new Error "Error occured. Please try again." if err
                        callback err, unless err then username

  @fetchRegistrationDetails = (token, callback) ->
    JAccount = require './account'

    @one { token, status: 'active' }, (err, certificate) ->
      return callback err  if err
      return callback { message: 'Unrecognized token!' }  unless certificate

      { email, username } = certificate

      JAccount.one 'profile.nickname': username, (err, account) ->
        return callback err  if err
        return callback { message: 'Unrecognized token!' }  unless account

        { firstName, lastName } = account.profile

        callback null, { firstName, lastName, email }

  expire:(callback)-> @update {$set: status: 'expired'}, callback
  redeem:(callback)-> @update {$set: status: 'redeemed'}, callback
