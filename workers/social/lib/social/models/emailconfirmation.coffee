jraphical = require 'jraphical'

module.exports = class JEmailConfirmation extends jraphical.Module

  crypto      = require 'crypto'
  createSalt  = require 'hat'

  @share()

  @set
    sharedMethods:
      static    : ['confirmByToken']
    schema      :
      email     :
        type    : String
        email   : yes
      salt      : String
      token     : String
      username  : String
      status    :
        type    : String
        enum    : [
          'invalid status code'
          ['unconfirmed','confirmed']
        ]

  @confirmByToken = (token, callback)->
    JUser = require './user'
    @one {token}, (err, confirmation)->
      if err or !confirmation?
        callback new KodingError err.message or 'Unrecogized token.'
      else
        confirmation.confirm (err)->
          if err
            callback err
          else
            JUser.one email: confirmation.getAt('email'), (err, user)->
              if err
                callback err
              else
                user.confirmEmail callback

  @create =(user, callback)->
    email = user.getAt('email')
    salt = createSalt()
    token = crypto.createHash('sha1').update(salt+email).digest('hex')
    confirmation = new JEmailConfirmation {
      email
      salt
      token
      username: user.getAt('username')
      status: 'unconfirmed'
    }
    confirmation.save (err)->
      if err
        callback err
      else
        user.addEmailConfirmation confirmation, (err)->
          if err
            callback err
          else
            callback null, confirmation

  getSubject:-> 'Please confirm your email address.'

  getTextBody:->
    {host, protocol} = require('../config.email')
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
