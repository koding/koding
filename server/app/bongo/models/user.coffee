class JUser extends jraphical.Module
  
  @hashUnhashedPasswords =->
    @all {salt: $exists: no}, (err, users)->
      users.forEach (user)-> user.changePassword user.getAt('password')
  
  hashPassword =(value, salt)->
    require('crypto').createHash('sha1').update(salt+value).digest('hex')
    
  createSalt = require 'hat'
  
  @share()
  
  @set
    indexes         :
      username      : 'unique'
      email         : 'unique'

    sharedMethods   :
      instance      : []
      static        : [
        'login','logout','register','usernameAvailable','emailAvailable','changePassword'
        'fetchUser','setDefaultHash','whoami'
      ]

    schema          :
      username      :
        type        : String
        validate    : (value)->
          3 < value.length < 26 and /^[^-][a-z0-9-]+$/.test value
        set         : (value)-> value.toLowerCase()
      email         :
        type        : String
        email       : yes
      password      : String
      salt          : String
      status        : 
        type        : String
        enum        : [
          'invalid status type', [
            'unconfirmed','confirmed','blocked'
          ]
        ]
        default     : 'unconfirmed'
      registeredAt  :
        type        : Date
        default     : -> new Date
      lastLoginDate :
        type        : Date
        default     : -> new Date
      tenderAppLink : String
      emailFrequency: Object

    relationships       :
      ownAccount        :
        targetType      : JAccount
        as              : 'owner'
      emailConfirmation :
        targetType      : JEmailConfirmation
        as              : 'confirmation'
  
  sessions  = {}
  users     = {}
  guests    = {}

  # @fetchUser = bongo.secure (client,options,callback)->
  #   {username} = options
  #   constructor = @
  #   connection.remote.fetchClientId (clientId)->
  #     visitor = JVisitor.visitors[clientId]
  #     unless visitor
  #       callback new KodingError 'No visitor instance was found.'
  #     else
  #       constructor.one {username}, callback
  
  createNewMemberActivity =(account, callback=->)->
    bucket = new CNewMemberBucket
      anchor      : account
      sourceName  : 'JAccount'
    bucket.save (err)->
      if err
        callback err
      else
        activity = CBucketActivity.create bucket
        activity.save (err)->
          if err
            callback err
          else
            activity.addSubject bucket, (err)->
              if err
                callback err
              else
                activity.update
                  $set          :
                    snapshot    : JSON.stringify(bucket)
                  $addToSet     :
                    snapshotIds : bucket.getId()
                , callback
  
  getHash =(value)->
    require('crypto').createHash('md5').update(value.toLowerCase()).digest('hex')
  
  fetchTenderAppLink : (callback)->
    {username,email} = @
    nodeRequest.get uri: "http://devrim.kodingen.com/_/tender.php?name=#{username}&email=#{email}", (err,res,body)->
      if err
        callback err
      else
        callback null, body
  
  @setDefaultHash =->
    JUser.all {}, (err, users)->
      users.forEach (user)->
        user.fetchOwnAccount (err, account)->
          account.profile.hash = getHash user.email
          account.save (err)-> throw err if err
  
  @whoami = bongo.secure ({connection:{delegate}}, callback)-> callback delegate 
  
  @login = bongo.secure ({connection}, credentials, callback)->
    {username, password} = credentials
    constructor = @
    connection.remote.fetchClientId (clientId)->
      visitor = JVisitor.visitors[clientId]
      unless visitor
        callback new KodingError 'No visitor instance was found.'
      JUser.one {username, status: $ne: 'blocked'}, (err, user)->
        if err
          callback new KodingError err.message
        else unless user?
          callback new KodingError 'Unknown username!'
        else unless user.getAt('password') is hashPassword password, user.getAt('salt')
          callback new KodingError 'Access denied!'
        else
          JSession.one {clientId}, (err, session)->
            if err
              callback err
            else unless session
              callback new KodingError 'Could not restore your session!'
            else
              session.update {
                $set            :
                  username      : user.username
                  lastLoginDate : new Date
                $addToSet       :
                  tokens        :
                    token       : hat()
                    expires     : new Date(Date.now() + 1000*60*60*24*14)
                    authority   : 'beta.koding.com'
                    requester   : 'api.koding.com'
              }, (err)->
                if err
                  callback err
                else
                  if err
                    callback err
                  else user.fetchOwnAccount (err, account)->
                    if err
                      callback err
                    else
                      connection.delegate = account
                      callback null, account
                      visitor.emit ['change','login'], account
                      userToCreate = user.get()
                      user.fetchTenderAppLink (err, link)->
                        if err
                          console.log err
                        else
                          user.update $set: tenderAppLink: link, (err)->
                            if err
                              console.log err
                            else
                              console.log 'user link was added'
  
  @logout = bongo.secure ({connection}, callback)->
    connection.remote.fetchClientId (clientId)->
      visitor = JVisitor.visitors[clientId]
      JSession.one {clientId}, (err, session)->
        if err
          callback err
        else if session
          session.update {
            $unset      :
              username  : 1
              tokens    : 1
          }, (err, docs)->
            if err
              callback err
            else
              {guestId} = session
              JGuest.one {guestId}, (err, guest)->
                if err
                  callback err
                else if guest
                  connection.delegate = guest
                  callback null, guest
                  visitor.emit ['change','logout'], guest
        else callback new KodingError 'Could not restore your session!'
  
  @verifyEnrollmentEligibility = ({email, inviteCode}, callback)->    
    if inviteCode
      JInvitation.one {
        code: inviteCode
        status: 'active'
      }, (err, invite)->
        # callback null, yes, invite
        if err or !invite? 
          callback new KodingError 'Invalid invitation ID!'
        else 
          callback null, yes, invite
  
  @verifyKodingenPassword = ({username, password, kodingenUser}, callback)->
    if kodingenUser isnt 'on'
      callback null
    else
      require('https').get
        hostname  : 'kodingen.com'
        path      : "/bridge_.php?username=#{encodeURIComponent username}&password=#{encodeURIComponent password}"
      , (res)->
        data = ''
        res.setEncoding 'utf-8'
        res.on 'data', (chunk)-> data += chunk
        res.on 'error', (err)-> callback err, r
        res.on 'end', ->
          data = JSON.parse data.substr(1, data.length - 2)
          if data.error then callback yes else callback null

  @register = bongo.secure (client, userFormData, callback)->
    {connection} = client
    {username, email, password, passwordConfirm, 
     firstName, lastName, agree, inviteCode, kodingenUser} = userFormData
    @usernameAvailable username, (err, isAvailable)=>
      if err
        callback err
      else unless isAvailable
        callback new KodingError 'That username is not available!'
      else
        @verifyEnrollmentEligibility {email, inviteCode}, (err, isEligible, invite)=>
          if err
            callback new KodingError err.message
          else
            if passwordConfirm isnt password
              return callback new KodingError 'Passwords must be the same'
            else if agree isnt 'on'
              return callback new KodingError 'You have to agree to the TOS'
            else if not username? or not email?
              return callback new KodingError 'Username and email are required fields'
            
            @verifyKodingenPassword {username, password, kodingenUser}, (err)->
              if err
                return callback new KodingError 'Wrong password'
              else
                nickname = username
                connection.remote.fetchClientId (clientId)->
                  visitor = JVisitor.visitors[clientId]
                  JSession.one {clientId}, (err, session)->
                    if err
                      callback err
                    else unless session
                      callback new KodingError 'Could not restore your session!'
                    else
                      salt = createSalt()
                      user = new JUser {
                        username
                        email
                        salt
                        password: hashPassword(password, salt)
                      }
                      user.save (err)->
                        if err
                          callback err
                        else
                          hash = getHash email
                          account = new JAccount
                            profile: {
                              nickname
                              firstName
                              lastName
                              hash
                            }
                          account.save (err)->
                            if err
                              callback err
                            else
                              user.addOwnAccount account, (err)->
                                if err
                                  callback err
                                else
                                  session.update {
                                    $set:
                                      username: user.username
                                    $addToSet:
                                      tokens        :
                                        token       : hat()
                                        expires     : new Date(Date.now() + 1000*60*60*24*14)
                                        authority   : 'beta.koding.com'
                                        requester   : 'api.koding.com'
                                  }, (err, docs)->
                                    if err
                                      callback err
                                    else
                                      invite?.redeem? client
                                      connection.delegate = account
                                      visitor.emit ['change','login'], account
                                      user.fetchTenderAppLink (err, link)->
                                        if err
                                          console.log err
                                        else
                                          user.update $set: tenderAppLink: link, (err)->
                                            if err
                                              console.log err
                                            else
                                              user.sendEmailConfirmation()
                                              createNewMemberActivity account
                                              # added by sinan 30 apr 2012, is that ok??? success state wasnt firing callback
                                              callback?()
  
  
  @fetchUser = bongo.secure ({connection},callback)->
    connection.remote.fetchClientId (clientId)->
      JSession.one {clientId},(err,session)->
        if err
          callback err
        else
          {username} = session
          JUser.one {username}, (err, user)->
            callback null, user

  @changePassword = bongo.secure (client,password,callback)->
    @fetchUser client, (err,user)-> user.changePassword password, callback
  
  @emailAvailable = (email, callback)->
    @count {email}, (err, count)->
      if err
        callback err
      else if count is 1
        callback null, no
      else
        callback null, yes

  @usernameAvailable = (username, callback)->
    username += ''
    r =
      kodingUser   : no
      kodingenUser : no
    
    @count {username}, (err, count)->
      if err
        callback err
      else
        r.kodingUser = if count is 1 then yes else no
        require('https').get
          hostname  : 'kodingen.com'
          path      : "/bridge.php?username=#{username}"
        , (res)->
          res.setEncoding 'utf-8'
          res.on 'data', (chunk)->
            r.kodingenUser = if !+chunk then no else yes
            callback null, r
          res.on 'error', (err)-> callback err, r
  
  changePassword:(newPassword, callback)->
    salt = createSalt()
    @update $set: {
      salt
      password: hashPassword(newPassword, salt)
    }, callback
  
  sendEmailConfirmation:(callback=->)->
    JEmailConfirmation.create @, (err, confirmation)->
      if err
        callback err
      else
        confirmation.send callback
  
  confirmEmail:(callback)-> @update {$set: status: 'confirmed'}, callback
  block:(callback)-> @update {$set: status: 'blocked'}, callback
