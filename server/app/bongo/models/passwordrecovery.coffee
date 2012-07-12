class JPasswordRecovery extends jraphical.Module
  
  createId = require 'hat'
  
  @share()
  
  @set
    sharedMethods :
      static      : [
        'validate','recoverPassword','recoverPasswordByEmail'
        'recoverPasswordByUsername','resetPassword'
      ]
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
        enum      : [
          'invalid status code'
          ['active','expired','redeemed','invalidated']
        ]
      requestedAt :
        type      : Date
        default   : -> new Date

  @getPasswordRecoveryEmail =-> 'hi@koding.com'

  @getPasswordRecoverySubject = -> '[Koding] Instructions to reset your password'
  
  @getEmailDateFormat = -> 'fullDate'
  
  @getPasswordRecoveryMessage = ({requestedAt, url})->
    """
    At #{dateFormat requestedAt, 'shortTime'} on #{dateFormat requestedAt, 'shortDate'}, you requested to reset your password.
    
    This one-time token will allow you to reset your password.  This token will self-destruct 30 minutes after it is issued.
    
    #{url}
    """
  
  @recoverPassword = bongo.secure (client, usernameOrEmail, callback)->
    if JUser.validateAt 'email', usernameOrEmail
      @recoverPasswordByEmail client, usernameOrEmail, callback
    else if JUser.validateAt 'username', usernameOrEmail
      @recoverPasswordByUsername client, usernameOrEmail, callback
    else callback new KodingError 'Invalid input.'

  @recoverPasswordByUsername = bongo.secure (client, username, callback)->
    {delegate} = client.connection
    unless delegate instanceof JGuest
      callback new KodingError 'You are already logged in.'
    else
      JUser.one {username}, (err, user)=>
        unless user then callback new KodingError "Unknown username"
        else @create client, user.getAt('email'), callback

  @recoverPasswordByEmail = bongo.secure (client, email, callback)->
    {delegate} = client.connection
    unless delegate instanceof JGuest
      callback new KodingError 'You are already logged in.'
    else
      JUser.count {email}, (err, num)=>
        unless num then callback null # pretend like everything went fine.
        else @create client, email, callback

  
  @create = bongo.secure ({connection:{delegate}}, email, callback)->
    token = createId()
    JUser.one {email}, (err, user)=>
      if err
        callback err
      else
        certificate = new JPasswordRecovery {
          email
          token
          username  : user.getAt('username')
          status    : 'active'
        }
        certificate.save (err)=>
          if err
            callback err
          else
            {host, port} = server
            protocol = if host is 'localhost' then 'http://' else 'https://'
            messageOptions =
              # url         : "#{protocol}#{host}:#{port}/recover/#{encodeURIComponent token}"
              url         : "#{protocol}#{host}/recover/#{encodeURIComponent token}"
              requestedAt : certificate.getAt('requestedAt')
            postmark.send
              From      : @getPasswordRecoveryEmail()
              To        : email
              Subject   : @getPasswordRecoverySubject()
              TextBody  : @getPasswordRecoveryMessage(messageOptions)
            , (err)-> callback err

  @validate = bongo.secure ({connection:{delegate}}, token, callback)->
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
      else callback null, yes
  
  @invalidate =(query, callback)->
    query.status = 'active'
    @update query, {$set: status: 'invalidated'}, callback
  
  @resetPassword = bongo.secure (client, token, newPassword, callback)->
    {delegate} = client.connection
    unless delegate instanceof JGuest
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
                      callback err, unless err then username
                
  expire:(callback)-> @update {$set: status: 'expired'}, callback
  redeem:(callback)-> @update {$set: status: 'redeemed'}, callback