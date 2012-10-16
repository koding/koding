jraphical = require 'jraphical'

Flaggable = require '../traits/flaggable'

module.exports = class JUser extends jraphical.Module
  {secure} = require 'bongo'
  {daisy} = require 'sinkrow'

  JAccount  = require './account'
  JSession  = require './session'
  JGuest    = require './guest'
  JInvitation = require './invitation'
  #JFeed     = require './feed'

  createId = require 'hat'

  createKodingError =(err)->
    if 'string' is typeof err
      message: err
    else
      message: err.message

  @bannedUserList = ['abrt','amykhailov','apache','about','visa',
                     'cthorn','daemon','dbus','dyasar','ec2-user',
                     'games','ggoksel','gopher','haldaemon','halt','mail',
                     'nfsnobody','nginx','nobody','node','operator',
                     'root','rpcuser','saslauth','shutdown','sinanlocal',
                     'sshd','sync','tcpdump','uucp','vcsa','zabbix',
                     'search','blog','activity','guest','credits','about',
                     'kodingen','alias','backup','bin','bind','daemon',
                     'Debian-exim','dhcp','drweb','games','gnats','klog',
                     'kluser','libuuid','list','mhandlers-user','more',
                     'mysql','nagios','news','nobody','popuser','postgres',
                     'proxy','psaadm','psaftp','qmaild','qmaill','qmailp',
                     'qmailq','qmailr','qmails','sshd','statd','sw-cp-server',
                     'sync','syslog','tomcat','tomcat55','uucp','what',
                     'www-data','fuck','porn','p0rn','porno','fucking',
                     'fucker','admin','postfix','puppet','main','invite',
                     'administrator','members','register','activate',
                     'groups','blogs','forums','topics','develop','terminal',
                     'term','twitter','facebook','google','framework']

  @hashUnhashedPasswords =->
    @all {salt: $exists: no}, (err, users)->
      users.forEach (user)-> user.changePassword user.getAt('password')

  hashPassword =(value, salt)->
    require('crypto').createHash('sha1').update(salt+value).digest('hex')

  createSalt = require 'hat'

  @share()

  @trait __dirname, '../traits/flaggable'

  @getFlagRole =-> 'owner'

  @set
    broadcastable   : no
    indexes         :
      username      : 'unique'
      email         : 'unique'

    sharedMethods   :
      instance      : ['sendEmailConfirmation']
      static        : [
        'login','logout','register','usernameAvailable','emailAvailable','changePassword','changeEmail'
        'fetchUser','setDefaultHash','whoami','isRegistrationEnabled'
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
        targetType      : 'JEmailConfirmation'
        as              : 'confirmation'

  sessions  = {}
  users     = {}
  guests    = {}

  # @fetchUser = Bongo.secure (client,options,callback)->
  #   {username} = options
  #   constructor = @
  #   connection.remote.fetchClientId (clientId)->
  #     visitor = JVisitor.visitors[clientId]
  #     unless visitor
  #       callback new KodingError 'No visitor instance was found.'
  #     else
  #       constructor.one {username}, callback

  @isRegistrationEnabled =(callback)->
    JRegistrationPreferences = require './registrationpreferences'
    JRegistrationPreferences.one {}, (err, prefs)->
      callback err? or prefs?.isRegistrationEnabled or no

  @authenticateClient:(clientId, callback=->)->
    JSession.one {clientId}, (err, session)->
      if err
        callback createKodingError err
      else unless session?
        JGuest.obtain null, clientId, callback
      else
        {username, guestId} = session
        if guestId?
          JGuest.one {guestId}, (err, guest)=>
            if err
              callback createKodingError err
            else if guest?
              callback null, guest
            else
              @logout clientId, callback
        else if username?
          JUser.one {username}, (err, user)->
            if err
              callback? err
            else
              user.fetchOwnAccount (err, account)->
                if err
                  callback createKodingError err
                else
                  callback null, account
        else @logout clientId, callback


  createNewMemberActivity =(account, callback=->)->
    CNewMemberBucket = require './bucket/newmemberbucket'
    CBucketActivity = require './activity/bucketactivity'
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
    @all {}, (err, users)->
      users.forEach (user)->
        user.fetchOwnAccount (err, account)->
          account.profile.hash = getHash user.email
          account.save (err)-> throw err if err

  @whoami = secure ({connection:{delegate}}, callback)-> callback delegate

  @login = secure ({connection}, credentials, callback)->
    {username, password, clientId} = credentials
    constructor = @
    JUser.one {username, status: $ne: 'blocked'}, (err, user)->
      if err
        callback createKodingError err.message
      else unless user?
        callback createKodingError 'Unknown username!'
      else unless user.getAt('password') is hashPassword password, user.getAt('salt')
        callback createKodingError 'Access denied!'
      else
        JSession.one {clientId}, (err, session)->
          if err
            callback err
          else unless session
            callback createKodingError 'Could not restore your session!'
          else
            replacementToken = createId()
            console.log 'replacement token', replacementToken
            JGuest.recycle session.guestId
            session.update {
              $set            :
                username      : user.username
                lastLoginDate : new Date
                clientId      : replacementToken
              $unset:
                guestId       : 1
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
                    JAccount.emit "AccountLoggedIn", account
                    callback null, account, replacementToken

  @logout = secure (client, callback)->
    if 'string' is typeof clientId
      sessionToken = client
    else
      {sessionToken} = client
      delete client.connection.delegate
      delete client.sessionToken
    JSession.cycleSession sessionToken, callback

  @verifyEnrollmentEligibility = ({email, inviteCode}, callback)->
    JRegistrationPreferences = require './registrationpreferences'
    JInvitation = require './invitation'
    JRegistrationPreferences.one {}, (err, prefs)->
      if err
        callback err
      else unless prefs.isRegistrationEnabled
        callback new Error 'Registration is currently disabled!'
      else if inviteCode
        JInvitation.one {
          code: inviteCode
          status: $in : ['active','sent']
        }, (err, invite)->
          # callback null, yes, invite
          if err or !invite?
            callback createKodingError 'Invalid invitation ID!'
          else
            callback null, yes, invite
      else
        callback createKodingError 'Invitation code is required!'

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

  @register = secure (client, userFormData, callback)->
    {connection} = client
    {username, email, password, passwordConfirm, firstName, lastName,
     agree, inviteCode, kodingenUser, clientId} = userFormData
    @usernameAvailable username, (err, r)=>
      isAvailable = yes

      # r =
      #   forbidden    : yes/no
      #   kodingenUser : yes/no
      #   kodingUser   : yes/no

      if err
        callback err
      else if r.forbidden
        callback createKodingError 'That username is forbidden!'
      else if r.kodingUser
        callback createKodingError 'That username is taken!'
      else
        @verifyEnrollmentEligibility {email, inviteCode}, (err, isEligible, invite)=>
          if err
            callback createKodingError err.message
          else
            if passwordConfirm isnt password
              return callback createKodingError 'Passwords must be the same'
            else if agree isnt 'on'
              return callback createKodingError 'You have to agree to the TOS'
            else if not username? or not email?
              return callback createKodingError 'Username and email are required fields'

            @verifyKodingenPassword {username, password, kodingenUser}, (err)->
              if err
                return callback createKodingError 'Wrong password'
              else
                nickname = username
                JSession.one {clientId: client.sessionToken}, (err, session)->
                  if err
                    callback err
                  else unless session
                    callback createKodingError 'Could not restore your session!'
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
                        if err.code is 11000
                          callback createKodingError "Sorry, \"#{email}\" is already in use!"
                        else callback err
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
                                replacementToken = createId()
                                session.update {
                                  $set:
                                    username      : user.username
                                    lastLoginDate : new Date
                                    clientId      : replacementToken
                                  $unset          :
                                    guestId       : 1
                                }, (err, docs)->
                                  if err
                                    callback err
                                  else
                                    user.sendEmailConfirmation()
                                    JInvitation.grant {'profile.nickname': user.username}, 3, (err)->
                                      console.log 'An error granting invitations', err if err
                                    createNewMemberActivity account
                                    console.log replacementToken
                                    callback null, account, replacementToken


  @fetchUser = secure (client, callback)->
    JSession.one {clientId: client.sessionToken}, (err, session)->
      if err
        callback err
      else
        {username} = session
        JUser.one {username}, (err, user)->
          callback null, user

  @changePassword = secure (client,password,callback)->
    @fetchUser client, (err,user)-> user.changePassword password, callback

  @changeEmail = secure (client,options,callback)->

    {email} = options

    @emailAvailable email, (err, res)=>

      if err
        callback createKodingError "Something went wrong please try again!"
      else if res is no
        callback createKodingError "Email is already in use!"
      else
        @fetchUser client, (err,user)->
          account = client.connection.delegate
          user.changeEmail account, options, callback

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
      forbidden    : yes

    @count {username}, (err, count)=>
      if err or username.length < 4 or username.length > 25
        callback err, r
      else
        r.kodingUser = if count is 1 then yes else no
        r.forbidden = if username in @bannedUserList then yes else no
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

  changeEmail:(account, options, callback)->

    JVerificationToken = require './verificationtoken'

    {email, pin} = options

    if not pin
      options =
        action    : "update-email"
        user      : @
        email     : email

      JVerificationToken.requestNewPin options, callback

    else
      options =
        action    : "update-email"
        username  : @getAt 'username'
        email     : email
        pin       : pin

      JVerificationToken.confirmByPin options, (err, confirmed)=>

        if err then callback err
        else if confirmed
          @update $set: {email}, (err, res)=>
            if err
              callback err
            else
              account.profile.hash = getHash email
              account.save (err)-> throw err if err
              callback null
        else
          callback new KodingError 'PIN is not confirmed.'

  sendEmailConfirmation:(callback=->)->
    JEmailConfirmation = require './emailconfirmation'
    JEmailConfirmation.create @, (err, confirmation)->
      if err
        callback err
      else
        confirmation.send callback

  confirmEmail:(callback)-> @update {$set: status: 'confirmed'}, callback
  block:(callback)-> @update {$set: status: 'blocked'}, callback
