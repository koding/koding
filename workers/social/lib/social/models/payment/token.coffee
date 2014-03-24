{Module} = require 'jraphical'

module.exports = class JPaymentToken extends Module

  {secure, signature}    = require 'bongo'
  crypto      = require 'crypto'

  Emailer     = require '../../emailer'
  JUser       = require '../user'

  @share()

  @set
    sharedEvents  :
      static      : []
      instance    : []
    sharedMethods :
      static      :
        checkToken:
          (signature Object, Function)
        createToken:
          (signature Object, Function)
    schema        :
      userCode    : String
      planCode    : String
      pin         : String
      tries       : Number
      createdAt   :
        type      : Date
        default   : -> new Date

  @checkToken = secure ({connection:{delegate}}, data, callback)->
    # CAUTION: we do not ask for nor validate token for now
    return callback yes

    @one
      userCode: delegate.profile.nickname
      planCode: data.planCode
    , (err, token)->
      return callback err  if err
      return callback new KodingError 'Token not found!'  unless token
      token.tries ?= 0
      return callback new KodingError 'Too many tries'    if token.tries > 2

      if token.pin is data.pin
        callback null
      else
        token.tries++
        token.save (err)->
          return callback err  if err
          return callback new KodingError 'Incorrect PIN'

  @createToken = secure (client, data, callback)->
    {delegate} = client.connection

    @one
      userCode: delegate.profile.nickname
      planCode: data.planCode
    , (err, token)=>
      pin = Math.floor Math.random() * 10001

      # Create entry if necessary
      if err or not token
        token = new JPaymentToken
          userCode: delegate.profile.nickname
          planCode: data.planCode

      # Assign a (new) PIN.
      token.pin   = pin.toString()
      token.tries = 0

      # Send email
      # TODO: use emailSender (with Koding template)
      token.save (err)->
        return callback err  if err
        JUser.fetchUser client, (e, r)->
          email     = r.email
          firstName = delegate.profile.firstName

          body =
            """
            Hi #{firstName},

            You can use following pin to complete your request:

              #{pin}

            --
            Koding Team

            """

          Emailer.send
            From      : 'hello@koding.com'
            To        : email
            Subject   : 'PIN for Subscription'
            TextBody  : body
          , callback


class PINExistsError extends Error

  constructor:(message)->
    return new PINExistsError(message)  unless this instanceof PINExistsError
    Error.call this
    @message = message
    @name    = 'PINExistsError'
