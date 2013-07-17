jraphical = require 'jraphical'

Flaggable = require '../../traits/flaggable'

module.exports = class JUser extends jraphical.Module
  {secure}       = require 'bongo'
  {daisy, dash}  = require 'sinkrow'

  JAccount       = require '../account'
  JSession       = require '../session'
  JGuest         = require '../guest'
  JInvitation    = require '../invitation'
  JName          = require '../name'
  JGroup         = require '../group'
  JLog           = require '../log'

  createId       = require 'hat'

  {Relationship} = jraphical

  createKodingError =(err)->
    if 'string' is typeof err
      message: err
    else
      message: err.message

  @bannedUserList = ['abrt','amykhailov','apache','about','visa','shared-',
                     'cthorn','daemon','dbus','dyasar','ec2-user','http',
                     'games','ggoksel','gopher','haldaemon','halt','mail',
                     'nfsnobody','nginx','nobody','node','operator','https',
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
                     'administrator','members','register','activate','shared',
                     'groups','blogs','forums','topics','develop','terminal',
                     'term','twitter','facebook','google','framework', 'kite']

  @hashUnhashedPasswords =->
    @all {salt: $exists: no}, (err, users)->
      users.forEach (user)-> user.changePassword user.getAt('password')

  hashPassword =(value, salt)->
    require('crypto').createHash('sha1').update(salt+value).digest('hex')

  createSalt = require 'hat'

  @share()

  @trait __dirname, '../../traits/flaggable'

  @getFlagRole =-> 'owner'

  @set
    softDelete      : yes
    broadcastable   : no
    indexes         :
      username      : 'unique'
      email         : 'unique'

    sharedEvents    : {}
      # static        : [
      #   { name: 'UserCreated' }
      # ]
    sharedMethods   :
      instance      : ['sendEmailConfirmation']
      static        : [
        'login','logout','register','usernameAvailable','emailAvailable',
        'changePassword','changeEmail','fetchUser','setDefaultHash','whoami',
        'isRegistrationEnabled','convert','setSSHKeys', 'getSSHKeys'
      ]

    schema          :
      username      :
        type        : String
        validate    : require('../name').validateName
        set         : (value)-> value.toLowerCase()
      oldUsername   : String
      uid           :
        type        : Number
        set         : Math.floor
      email         :
        type        : String
        email       : yes
      password      : String
      salt          : String
      blockedUntil  : Date
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
      emailFrequency: Object
      onlineStatus  :
        actual      :
          type      : String
          enum      : ['invalid status',['online','offline']]
          default   : 'online'
        userPreference:
          type      : String
          # enum      : ['invalid status',['online','offline','away','busy']]

      sshKeys       : [Object]

    relationships       :
      ownAccount        :
        targetType      : JAccount
        as              : 'owner'
      leasedAccount     :
        targetType      : JAccount
        as              : 'leasor'
      emailConfirmation :
        targetType      : require '../emailconfirmation'
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
    JRegistrationPreferences = require '../registrationpreferences'
    JRegistrationPreferences.one {}, (err, prefs)->
      callback err? or prefs?.isRegistrationEnabled or no

  @authenticateClient:(clientId, context, callback)->
    JSession.one {clientId}, (err, session)->
      if err
        callback createKodingError err
      else unless session?
        JUser.createTemporaryUser callback
#        JGuest.obtain null, clientId, callback
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
              callback createKodingError err
            else unless user?
              callback createKodingError 'Unknown user!'
            else
              user.fetchAccount context, (err, account)->
                if err
                  callback createKodingError err
                else
                  #JAccount.emit "AccountAuthenticated", account
                  callback null, account
        else @logout clientId, callback


  createNewMemberActivity =(account, callback=->)->
    CNewMemberBucket = require '../bucket/newmemberbucket'
    CBucketActivity = require '../activity/bucketactivity'
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
                , ->
                  CActivity = require "../activity"
                  CActivity.emit "ActivityIsCreated", activity
                  callback()

  getHash =(value)->
    require('crypto').createHash('md5').update(value.toLowerCase()).digest('hex')

  @setDefaultHash =->
    @all {}, (err, users)->
      users.forEach (user)->
        user.fetchOwnAccount (err, account)->
          account.profile.hash = getHash user.email
          account.save (err)-> throw err if err

  @whoami = secure ({connection:{delegate}}, callback)-> callback delegate

  checkBlockedStatus = (user, callback)->
    if user.status is 'blocked'
      if user.blockedUntil and user.blockedUntil > new Date
        toDate = user.blockedUntil.toUTCString()
        message = """
            You cannot login until #{toDate}.
            At least 10 moderators of Koding have decided that your participation is not of acceptable kind.
            That's all I know.
            You can demand further explanation from ban@koding.com. Please allow 1-2 days to receive a reply.
            Your machines might be blocked, all types of activities might be suspended.
            Your data is safe, you can access them when/if ban is lifted.
          """
        callback createKodingError message
      else
        user.update {$set: status: 'unconfirmed'}, callback
    else
      callback null

  @login = secure ({connection}, credentials, callback)->
    {username, password, clientId} = credentials
    constructor = @
    JSession.one {clientId}, (err, session)->
      if err then callback err
      unless session then return callback createKodingError 'Could not restore your session!'

      bruteForceControlData =
        ip : session.clientIP
        username : username
      # todo add alert support(mail, log etc)
      JLog.checkLoginBruteForce bruteForceControlData, (res)->
        unless res then return callback createKodingError "Your login access is blocked for #{JLog.TIME_LIMIT_IN_MIN} minutes."
        JUser.one {username}, (err, user)->
          if err
            JLog.log { type: "login", username: username, success: no }
            , () ->
              callback createKodingError err.message
          else unless user?
            JLog.log { type: "login", username: username, success: no }
            , () ->
              callback createKodingError "Unknown user name"
          else unless user.getAt('password') is hashPassword password, user.getAt('salt')
            JLog.log { type: "login", username: username, success: no }
            , () ->
              callback createKodingError 'Access denied!'
          else
            checkBlockedStatus user, (err)->
              if err then return callback err
              replacementToken = createId()
              JGuest.recycle session.guestId
              session.update {
                $set            :
                  username      : user.username
                  lastLoginDate : new Date
                  clientId      : replacementToken
                $unset:
                  guestId       : 1
              }, (err)->
                  if err then callback err
                  user.fetchOwnAccount (err, account)->
                    if err then return callback err
                    connection.delegate = account
                    JAccount.emit "AccountAuthenticated", account

                    # This should be called after login and this
                    # is not correct place to do it, FIXME GG
                    # p.s. we could do that in workers
                    account.updateCounts()

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
    JRegistrationPreferences = require '../registrationpreferences'
    JInvitation = require '../invitation'
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

  @addToGroup = (account, slug, email, invite, callback)->
    JGroup.one {slug}, (err, group)->
      if err or not group then callback err
      else if invite? and invite.group isnt slug and group.privacy is 'private' and group.slug isnt 'koding'
        group.requestAccessFor account, callback
      else
        group.approveMember account, (err)->
          return callback err  if err
          cb = (invite)-> invite.markAccepted connection:delegate:account, callback
          if invite?.group is slug then cb invite
          else
            selector = {group: slug, inviteeEmail: email, status: 'sent'}
            (require '../invitation').one selector, (err, invite)->
              if invite and not err then cb invite
              else callback err

  @addToGroups = (account, invite, entryPoint, email, callback)->
    @addToGroup account, 'koding', email, invite, (err)=>
      if err then callback err
      else if (slug = invite?.group or entryPoint) and slug isnt 'koding'
        @addToGroup account, slug, email, invite, callback
      else
        callback null

  @createTemporaryUser = (callback) ->
    ((require 'koding-counter') {
      db          : @getClient()
      counterName : 'guest'
      offset      : 0
    }).next (err, guestId) =>
      return callback err  if err?

      username = "guest-#{guestId}"

      options     =
        username  : username
        email     : "#{username}@koding.com"
        password  : createId()

      @createUser options, (err, user, account) =>
        return callback err  if err?

        @addToGroup account, 'guests', null, null, (err) =>
          return callback err  if err?

          @configureNewAcccount account, user, createId(), callback


  @createUser = ({ username, email, password, firstName, lastName, silence }, callback)->
    slug =
      slug            : username
      constructorName : 'JUser'
      usedAsPath      : 'username'
      collectionName  : 'jUsers'

    JName.claim username, [slug], 'JUser', (err)=>
      if err then callback err
      else
        salt = createSalt()
        user = new JUser {
          username
          email
          salt
          password: hashPassword(password, salt)
          emailFrequency: {
            global         : on
            daily          : on
            privateMessage : on
            followActions  : off
            comment        : on
            likeActivities : off
            groupInvite    : on
            groupRequest   : on
            groupApproved  : on
          }
        }
        user.save (err)=>
          if err
            if err.code is 11000
              callback createKodingError "Sorry, \"#{email}\" is already in use!"
            else callback err
          else
            hash = getHash email
            account = new JAccount
              profile: {
                nickname: username
                firstName
                lastName
                hash
              }
              silence : silence # won't be saved, just for further processing
            account.save (err)=>
              if err then callback err
              else user.addOwnAccount account, (err) ->
                return callback err  if err
                callback null, user, account

  @configureNewAcccount = (account, user, replacementToken, callback) ->
    user.sendEmailConfirmation (err) -> console.error err  if err
    JUser.grantInitialInvitations user.username
    JUser.emit 'UserCreated', user
    createNewMemberActivity account
    JAccount.emit "AccountAuthenticated", account
    callback null, account, replacementToken


  @validateAll = (userFormData, callback) =>

    validate = require './validators'

    isError = no
    errors = {}

    queue = Object.keys(userFormData).map (field) => =>
      if field of validate
        validate[field].call this, userFormData, (err) =>
          if err?
            errors[field] = err
            isError = yes
          queue.fin()
      else queue.fin()

    dash queue, -> callback(
      if isError
      then { message: "Errors were encountered during validation", errors }
      else null
    )

  @changePasswordByUsername = (username, password, callback) ->
    salt = createSalt()
    hashedPassword = hashPassword password, salt
    @update { username }, {
      $set: { salt, password: hashedPassword }
    }, callback

  @changeEmailByUsername = (username, email, callback) ->
    @update { username }, { $set: { email }}, callback

  @changeUsernameByAccount = (account, username, clientId, callback)->
    account.changeUsername username, (err) =>
      return callback err  if err?
      return callback null  unless clientId?
      newToken = createId()
      JSession.one { clientId }, (err, session) =>
        if err?
          return callback createKodingError "Could not update your session"
        else if session?
          session.update { $set: { clientId: newToken, username }}, (err) ->
            return callback err  if err?
            callback null, newToken
        else
          callback createKodingError "Session not found!"


  @convert = secure (client, userFormData, callback) ->
    { connection, sessionToken : clientId } = client
    { delegate : account } = connection
    { nickname : oldUsername } = account.profile
    { username, email, password, passwordConfirm, firstName, lastName,
      agree, inviteCode, kodingenUser, entryPoint } = userFormData

    # only unreigstered accounts can be "converted"
    if account.status is "registered"
      return callback createKodingError "This account is already registered."

    @validateAll userFormData, (err) =>
      return callback err  if err?
      @changePasswordByUsername oldUsername, password, (err) =>
        return callback err  if err?
        @changeEmailByUsername oldUsername, email, (err) =>
          return callback err  if err?
          @changeUsernameByAccount account, username, clientId,
            (err, newToken) =>
              return callback err  if err?
              @addToGroups account, null, entryPoint, email, (err) ->
                return callback err  if err?
                account.update $set: {
                  'profile.firstName' : firstName
                  'profile.lastName'  : lastName
                  type                : 'registered'
                }, (err) =>
                  return callback err  if err?
                  callback null, newToken

  @register = secure (client, userFormData, callback) ->
    { connection } = client
    { username, email, password, passwordConfirm, firstName, lastName,
      agree, inviteCode, kodingenUser, entryPoint } = userFormData
    # The silence option provides silence registers,
    # means no welcome e-mail for new users.
    # We're using it for migrating Kodingen users to Koding
    silence  = no
    if client.connection?.delegate?.can? 'migrate-kodingen-users'
      {silence} = userFormData

    @validateUsername username, (err) ->
      return callback err  if err?

      @verifyEnrollmentEligibility {email, inviteCode}, (err, isEligible, invite) =>
        if err
          callback createKodingError err.message
        else
          if passwordConfirm isnt password
            return callback createKodingError 'Passwords must be the same'
          else if agree isnt 'on'
            return callback createKodingError 'You have to agree to the TOS'
          else if not username? or not email?
            return callback createKodingError 'Username and email are required fields'

          @verifyKodingenPassword {username, password, kodingenUser}, (err) =>
            if err
              return callback createKodingError 'Wrong password'
            else
              JSession.one {clientId: client.sessionToken}, (err, session) =>
                if err
                  callback err
                else unless session
                  callback createKodingError 'Could not restore your session!'
                else
                  userData = {
                    username, password, email, firstName, lastName
                  }
                  @createUser userData, (err, user, account) =>
                    return callback err  if err
                    @removeUnsubscription userData, (err)=>
                      return callback err  if err
                      @addToGroups account, invite, entryPoint, email, (err) ->
                        if err then callback err
                        else if silence
                          JUser.grantInitialInvitations user.username
                          createNewMemberActivity account
                          JUser.emit 'UserCreated', user
                          callback null, account
                        else
                          replacementToken = createId()
                          session.update {
                            $set:
                              username      : user.username
                              lastLoginDate : new Date
                              clientId      : replacementToken
                            $unset          :
                              guestId       : 1
                          }, (err, docs) ->
                            if err then callback err
                            else
                              @configureNewAcccount account, user, replacementToken, callback

  @removeUnsubscription:({email}, callback)->
    JUnsubscribedMail = require '../unsubscribedmail'
    JUnsubscribedMail.one {email}, (err, unsubscribed)->
      return callback err  if err or not unsubscribed
      unsubscribed.remove callback

  @grantInitialInvitations = (username)->
    JInvitation.grant {'profile.nickname': username}, 3, (err)->
      console.log 'An error granting invitations', err if err

  @fetchUser = secure (client, callback)->
    JSession.one {clientId: client.sessionToken}, (err, session)->
      if err
        callback err
      else
        {username} = session

        if username?
          JUser.one {username}, (err, user)->
            callback null, user
        else
          callback null

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

  fetchContextualAccount:(context, rest..., callback)->
    Relationship.one {
      as          : 'owner'
      sourceId    : @getId()
      targetName  : 'JAccount'
      'data.context': context
    }, (err, account)=>
      if err
        callback err
      else if account?
        callback null, account
      else
        @fetchOwnAccount rest..., callback

  fetchAccount:(context, rest...)->
    if context is 'koding' then @fetchOwnAccount rest...
    else @fetchContextualAccount context, rest...

  changePassword:(newPassword, callback)->
    salt = createSalt()
    @update $set: {
      salt
      password: hashPassword(newPassword, salt)
    }, callback

  changeEmail:(account, options, callback)->

    JVerificationToken = require '../verificationtoken'

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
          callback createKodingError 'PIN is not confirmed.'

  fetchHomepageView:(callback)->
    @fetchAccount 'koding', (err, account)->
      if err then callback err
      else account.fetchHomepageView callback

  sendEmailConfirmation:(callback=->)->
    JEmailConfirmation = require '../emailconfirmation'
    JEmailConfirmation.create @, (err, confirmation)->
      if err
        callback err
      else
        confirmation.send callback

  confirmEmail:(callback)-> @update {$set: status: 'confirmed'}, callback

  block:(blockedUntil, callback)->
    unless blockedUntil then return callback createKodingError "Blocking date is not defined"

    @update
      $set:
        status: 'blocked',
        blockedUntil : blockedUntil
    , callback

  @setSSHKeys: secure (client, sshKeys, callback)->
    @fetchUser client, (err,user)->
      user.sshKeys = sshKeys
      user.save callback

  @getSSHKeys: secure (client, callback)->
    @fetchUser client, (err,user)->
      callback user.sshKeys or []
