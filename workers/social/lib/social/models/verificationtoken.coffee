{ Module } = require 'jraphical'
KodingError = require '../error'

emailsanitize = require './user/emailsanitize'

class PINExistsError extends Error

  constructor:(message) ->

    return new PINExistsError(message) unless this instanceof PINExistsError

    Error.call this
    @message = message
    @name = 'PINExistsError'


module.exports = class JVerificationToken extends Module

  { secure } = require 'bongo'
  crypto     = require 'crypto'
  hat        = require 'hat'
  Tracker    = require './tracker'

  @share()

  @set
    sharedEvents  :
      static      : []
      instance    : []
    schema        :
      username    : String
      email       :
        type      : String
        email     : yes
        set       : emailsanitize
      pin         : String
      createdAt   :
        type      : Date
        default   : -> new Date
      action      :
        type      : String
        enum      : [
          'invalid action type'
          # Add verification required action types here before use
          ['update-email', 'verify-account', 'test-verify']
        ]

  isAlive = (confirmation) ->
    # 20 Min. default TTL for tokens
    Math.round((Date.now() - confirmation.createdAt) / 60000) < 20

  @requestNewPin = (options, callback) ->

    { action, email, subject, user, firstName, resendIfExists } = options

    email = emailsanitize email  if email

    subject   or= Tracker.types.REQUEST_EMAIL_CHANGE
    username    = user.getAt 'username'
    email     or= user.getAt 'email'
    firstName or= username

    if not email

      callback new KodingError 'E-mail is not provided!'

    else

      @one { username, action }, (err, confirmation) =>

        if confirmation and isAlive confirmation
          if resendIfExists
            confirmation.sendEmail { username, subject, firstName, action }, callback
          else
            callback if err then err else new PINExistsError \
              'PIN exists and not expired,
              try again after 20 min for new PIN.'

          return

        # Remove all waiting pins for given action and email
        @remove { username, action }, (err, count) =>

          return console.warn err  if err

          if count > 0 then console.log "#{count} expired PIN removed."
          else console.log 'No such waiting PIN found.'

          @createNewPin { username, action, email }, (err, confirmation) ->
            return callback err  if err

            confirmation.sendEmail { username, subject, firstName, action }, callback


  @confirmByPin = (options, callback) ->

    { pin, email, action, username } = options

    email = emailsanitize email

    @one { email, action, pin, username }, (err, confirmation) ->

      return callback err  if err

      if confirmation

        # Ignore the default TTL for `verify-account` actions ~ GG
        confirmed = isAlive confirmation
        callback null, if action is 'verify-account' then yes else confirmed

        confirmation.remove()
      else
        callback null, false


  sendEmail: ({ subject, firstName, username, action }, callback) ->

    Tracker.track username, { to:@email, subject }, { firstName, @pin, action }
    callback null


  @invalidatePin = (options, callback) ->
    { email, action, username } = options

    email = emailsanitize email

    @one { email, action, username }, (err, verify) ->
      return callback err  if err
      return callback new KodingError 'token not found' unless verify
      verify.remove()
      callback null


  @createNewPin = (options, callback) ->
    { username, action, email } = options
    pin = hat 16

    email = emailsanitize email

    confirmation = new JVerificationToken { username, action, email, pin }
    confirmation.save (err) -> callback err, confirmation
