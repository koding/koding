jraphical = require 'jraphical'

module.exports = class JEmailConfirmation extends jraphical.Module

  JUser       = require './user'
  JLog        = require './log'
  crypto      = require 'crypto'
  createSalt  = require 'hat'
  KodingError = require './../error'
  {secure}    = require 'bongo'

  @share()

  @set
    sharedMethods:
      static    : ['confirmByToken', 'resetToken']
    schema      :
      email     :
        type    : String
        email   : yes
      salt      : String
      token     : String
      username  : String
      createdAt :
        type    : Date
        default : -> new Date
      status    :
        type    : String
        enum    : [
          'invalid status code'
          ['unconfirmed','confirmed', 'obsolete']
        ]
#
#  @createMailSentLog = (username, success, callback)->
#    JLog.log { type: "emailConfirmationTokenSent", username, success }, callback

  @getUsernameFromFormData = (usernameOrEmail, callback)->
    JUser = require './user'
    if JUser.validateAt 'username', usernameOrEmail
      return callback null, usernameOrEmail
    else if JUser.validateAt 'email', usernameOrEmail
      JUser.one {email : usernameOrEmail }, (err, user)->
        return callback err if err
        return callback new KodingError 'Invalid User.' unless user
        return callback null, user.username
    else
      return callback new KodingError 'Invalid input.'

  @resetToken = (usernameOrEmail, callback)->
    @getUsernameFromFormData usernameOrEmail, (err, username)=>
      return callback err if err
      @some { username, status: "unconfirmed" }, {limit: 1, sort: { createdAt: -1} }, (err, confirmations)=>
        return callback err if err

        if confirmations and confirmations.length > 0
          createdAt = confirmations.first.createdAt
          # if it is resent in one day, do not send again
          if ((Date.now() - createdAt) / 1000 / 60 / 24) < 1
            return callback new KodingError "You can receive confirmation mail one a day"

        JUser = require './user'
        JUser.one {username}, (err, user)=>
          return callback err if err
          JEmailConfirmation.createAndSendEmail user, callback

  @confirmByToken = (token, callback)->
    @one {token}, (err, confirmation)->
      if err or !confirmation?
        return callback new KodingError err.message or 'Unrecogized token.'
      if confirmation.status is 'obsolete'
        return callback new KodingError "Please use your latest token or get another token"
      if confirmation.status is 'confirmed'
        return callback new KodingError "You have used your token before to confirm your account"

      confirmation.confirm (err)->
        return callback err if err

        JUser = require './user'
        JUser.one email: confirmation.getAt('email'), (err, user)->
          return callback err if err
          user.confirmEmail callback

  @createAndSendEmail = (user, callback)->
    return callback new KodingError "User is not defined" unless user
    @create user, (err, confirmation)->
      return callback err if err
      confirmation.send callback

  @create = (user, callback)->
    email = user.getAt('email')
    # update all existing confirmation mails as obsolete
    @update {email}, {$set: status: 'obsolete'}, {multi: true}, (err)->
      return callback err if err

      salt = createSalt()
      token = crypto.createHash('sha1').update(salt + email + "#{Date.now()}").digest('hex')
      confirmation = new JEmailConfirmation {
        email
        salt
        token
        username: user.getAt('username')
        status: 'unconfirmed'
      }

      confirmation.save (err)->
        return callback err if err
        user.addEmailConfirmation confirmation, (err)->
          return callback err if err
          callback null, confirmation

  getSubject:-> 'Please confirm your email address.'

  getTextBody:->
    { host, protocol } = require '../config.email'
    url = "#{protocol}//#{host}/Verify/#{encodeURIComponent @getAt('token')}"

    #
    # chris: you can do this at some point, i did setup kd.io/ domain.
    #
    # bitly.shorten url,(err,res)->
    #   unless err
    #     url = res.data.url

    """
    Hi #{@getAt('username')},

    Please confirm your email address in order to fully-activate your new Koding account.

    #{url}
    """

  confirm:(callback)-> @update {$set: status: 'confirmed'}, callback

  send:(callback)->
    JMail = require './email'
    email = new JMail
      from    : 'hello@koding.com'
      email   : @getAt('email')
      subject : @getSubject()
      content : @getTextBody()
      force   : yes

    email.save callback
