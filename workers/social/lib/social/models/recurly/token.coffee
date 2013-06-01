{Module} = require 'jraphical'

class PINExistsError extends Error
  constructor:(message)->
    return new PINExistsError(message) unless @ instanceof PINExistsError
    Error.call @
    @message = message
    @name = 'PINExistsError'

module.exports = class JRecurlyToken extends Module

  {secure}    = require 'bongo'
  crypto      = require 'crypto'

  Emailer     = require '../../emailer'
  JUser       = require '../user'

  @share()

  @set
    schema        :
      username    : String
      planCode    : String
      pin         : Number
      createdAt   :
        type      : Date
        default   : -> new Date
    sharedMethods     :
      static          : [
        'checkToken', 'createToken'
      ]

  @checkToken = secure (client, data, callback)->
    {delegate} = client.connection

    # For VIP beta only
    return callback yes

    JRecurlyToken.one
      username: delegate.profile.nickname
      planCode: data.planCode
      pin     : data.pin
    , (err, token)->
      if err or not token
        callback no
      else
        callback yes

  @createToken = secure (client, data, callback)->
    {delegate} = client.connection

    JRecurlyToken.one
      username: delegate.profile.nickname
      planCode: data.planCode
    , (err, token)=>
      pin = Math.floor Math.random() * 10001

      # Create entry if necessary
      if err or not token
        token = new JRecurlyToken
          username: delegate.profile.nickname
          planCode: data.planCode

      # Assign a (new) PIN.
      token.pin = pin

      # Send email
      token.save =>
        JUser.fetchUser client, (e, r)->
          email     = r.email
          firstName = delegate.profile.firstName

          body = """
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
          , ->
            callback()