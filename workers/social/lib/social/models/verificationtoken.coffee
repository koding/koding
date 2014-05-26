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
          ['update-email','test-verify']
        ]

  @requestNewPin = (options, callback)->

    {action, email, subject, user, firstName} = options
    subject   or= "Here is your code"
    username    = user.getAt 'username'
    email     or= user.getAt 'email'
    firstName or= username

    if not email
      KodingError = require '../error'
      callback new KodingError "E-mail is not provided!"
    else
      @one {username, action}, (err, verify)=>
        if verify
          if Math.round((Date.now()-verify.createdAt)/60000) < 20
            callback if err then err else new PINExistsError "PIN exists and not expired, try again after 20 min for new PIN."
            return no

        # Remove all waiting pins for given action and email
        @remove {username, action}, (err, count)->
          if err then console.warn err
          else
            if count > 0 then console.log "#{count} expired PIN removed."
            else console.log "No such waiting PIN found."

            # Create a random pin
            plainPin = hat 16
            pin      = crypto.createHash('sha1').update(plainPin+'').digest('hex')

            # Create and send new pin
            confirmation = new JVerificationToken {username, action, email, pin}
            confirmation.save (err)->
              if err
                callback err
              else
                JMail = require './email'
                email = new JMail
                  from    : 'hello@koding.com'
                  email   : email
                  subject : subject
                  content : confirmation.getTextBody firstName, plainPin
                  force   : yes

                email.save callback

  @confirmByPin = (options, callback)->

    {pin, email, action, username} = options

    # re-hash the pin
    pin = crypto.createHash('sha1').update(pin+'').digest('hex')

    @one {email, action, pin, username}, (err, verify)->
      if verify
        callback null, Math.round((Date.now()-verify.createdAt)/60000) < 20
        verify.remove()
      else
        callback err, false

  getTextBody:(firstName, plainPin)->
    """
    Hi #{firstName},

    You can use following code to complete your request:

      #{plainPin}

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
