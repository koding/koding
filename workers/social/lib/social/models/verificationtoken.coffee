{Module} = require 'jraphical'
KodingError = require '../error'

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

  isAlive = (confirmation)->
    # 20 Min. default TTL for tokens
    Math.round((Date.now()-confirmation.createdAt)/60000) < 20

  @requestNewPin = (options, callback)->

    {action, email, subject, user, firstName, resendIfExists} = options
    subject   or= "Here is your code"
    username    = user.getAt 'username'
    email     or= user.getAt 'email'
    firstName or= username

    if not email

      callback new KodingError "E-mail is not provided!"

    else

      @one {username, action}, (err, confirmation)=>

        if confirmation and isAlive confirmation
          if resendIfExists
            confirmation.sendEmail {subject, firstName, action}, callback
          else
            callback if err then err else new PINExistsError \
              "PIN exists and not expired,
              try again after 20 min for new PIN."

          return

        # Remove all waiting pins for given action and email
        @remove {username, action}, (err, count)->

          return console.warn err  if err

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
              confirmation.sendEmail {subject, firstName, action}, callback


  @confirmByPin = (options, callback)->

    {pin, email, action, username} = options

    @one {email, action, pin, username}, (err, confirmation)->

      return callback err  if err

      if confirmation

        # Ignore the default TTL for `verify-account` actions ~ GG
        confirmed = isAlive confirmation
        callback null, if action is 'verify-account' then yes else confirmed

        confirmation.remove()
      else
        callback null, false


  getTextBody = ({firstName, pin, action})->

    templates =

      'verify-account': """
        Thanks for signing up and welcome to Koding!

        Here's the confirmation code that you can use to verify your email address:

          <b>#{pin}</b>

        If you run into any issues, just reply to this email and help will be on its way!

        Have a nice day!

        --
        Koding Team
      """

      'update-email'  : """
        Hi #{firstName},

        To verify your new e-mail address you can use the following code:

          <b>#{pin}</b>

        Have a nice day!

        --
        Koding Team
      """

      default         : """
        Hi #{firstName},

        Here’s your koding.com verification code:

          <b>#{pin}</b>

        Have a nice day!

        --
        Koding Team
      """

    return templates[action] or templates.default


  sendEmail: ({subject, firstName, action}, callback)->

    JMail = require './email'

    email = new JMail
      from    : 'hello@koding.com'
      email   : @email
      subject : subject
      content : getTextBody {firstName, @pin, action}
      force   : yes
      replyto : 'support@koding.com'

    console.log "Pin (#{@pin}) sent to #{@email} for #{@action} action."

    email.save callback


  @invalidatePin = (options, callback)->
    {email, action, username} = options
    @one {email, action, username}, (err, verify)->
      return callback err  if err
      return callback new KodingError "token not found" unless verify
      verify.remove()
      callback null
