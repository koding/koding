{Module} = require 'jraphical'

class PINExistsError extends Error
  constructor:(message)->
    return new PINExistsError(message) unless @ instanceof PINExistsError
    Error.call @
    @message = message
    @name = 'PINExistsError'

module.exports = class JVerificationToken extends Module

  {secure}    = require 'bongo'
  crypto      = require 'crypto'
  hat         = require 'hat'

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

  @requestNewPin = (options, callback)->

    {action, email, subject, user, firstName, resendIfExists} = options
    subject   or= "Here is your code"
    username    = user.getAt 'username'
    email     or= user.getAt 'email'
    firstName or= username

    if not email

      KodingError = require '../error'
      callback new KodingError "E-mail is not provided!"

    else

      @one {username, action}, (err, confirmation)=>

        if confirmation
          createdAt = Math.round((Date.now()-confirmation.createdAt)/60000)

          if createdAt < 20 # min
            if resendIfExists
              confirmation.sendEmail {subject, firstName}, callback
            else
              callback if err then err else new PINExistsError \
                "PIN exists and not expired,
                try again after 20 min for new PIN."

            return

        # Remove all waiting pins for given action and email
        @remove {username, action}, (err, count)->
          if err then console.warn err
          else
            if count > 0 then console.log "#{count} expired PIN removed."
            else console.log "No such waiting PIN found."

            # Create a random pin
            pin = hat 16

            # Create and send new pin
            confirmation = new JVerificationToken {username, action, email, pin}
            confirmation.save (err)->
              if err
                callback err
              else
                confirmation.sendEmail {subject, firstName}, callback


  @confirmByPin = (options, callback)->

    {pin, email, action, username} = options

    @one {email, action, pin, username}, (err, confirmation)->

      return callback err  if err

      if confirmation
        callback null, Math.round((Date.now()-confirmation.createdAt)/60000) < 20
        confirmation.remove()
      else
        callback null, false


  sendEmail: ({subject, firstName}, callback)->

    JMail = require './email'

    email = new JMail
      from    : 'hello@koding.com'
      email   : @email
      subject : subject
      content : @getTextBody firstName, @pin
      force   : yes

    console.log "Pin (#{@pin}) sent to #{@email} for #{@action} action."

    email.save callback


  getTextBody: (firstName, plainPin)->

    """
    Hi #{firstName},

    Here’s your koding.com verification code:

      #{plainPin}

    Have a nice day!
    --
    Koding Team

    """


  @invalidatePin = (options, callback)->
    {email, action, username} = options
    @one {email, action, username}, (err, verify)->
      return callback err  if err
      return callback new KodingError "token not found" unless verify
      verify.remove()
      callback null
