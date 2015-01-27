jraphical = require 'jraphical'
Regions   = require 'koding-regions'
{argv}    = require 'optimist'
KONFIG    = require('koding-config-manager').load("main.#{argv.c}")
Flaggable = require '../../traits/flaggable'

module.exports = class JUser extends jraphical.Module
  {secure, signature, daisy, dash} = require 'bongo'

  JAccount        = require '../account'
  JSession        = require '../session'
  JInvitation     = require '../invitation'
  JName           = require '../name'
  JGroup          = require '../group'
  JLog            = require '../log'
  JMail           = require '../email'
  JPaymentPlan    = require '../payment/plan'
  JPaymentSubscription = require '../payment/subscription'
  Sendgrid        = require '../sendgrid'

  { v4: createId } = require 'node-uuid'

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
                     'term','twitter','facebook','google','framework', 'kite'
                     'landing','hello','dev']

  @hashUnhashedPasswords =->
    @all {salt: $exists: no}, (err, users)->
      users.forEach (user)-> user.changePassword user.getAt('password')

  hashPassword =(value, salt)->
    require('crypto').createHash('sha1').update(salt+value).digest('hex')

  createSalt = require 'hat'
  rack       = createSalt.rack 64

  @share()

  @trait __dirname, '../../traits/flaggable'

  @getFlagRole =-> 'owner'

  @set
    softDelete      : yes
    broadcastable   : no
    indexes         :
      username      : 'unique'
      email         : 'unique'
      'foreignAuth.github.foreignId'   : 'ascending'
      'foreignAuth.odesk.foreignId'    : 'ascending'
      'foreignAuth.facebook.foreignId' : 'ascending'
      'foreignAuth.google.foreignId'   : 'ascending'
      'foreignAuth.linkedin.foreignId' : 'ascending'
      'foreignAuth.twitter.foreignId'  : 'ascending'

    sharedEvents    :
      # do not share any events
      static        : []
      instance      : []
    sharedMethods   :
      # do not share any instance methods
      # instances     :
      static        :
        login                   : (signature Object, Function)
        logout                  : (signature Function)
        usernameAvailable       : (signature String, Function)
        emailAvailable          : (signature String, Function)
        changePassword          : (signature String, Function)
        changeEmail             : (signature Object, Function)
        fetchUser               : (signature Function)
        whoami                  : (signature Function)
        isRegistrationEnabled   : (signature Function)
        convert                 : (signature Object, Function)
        setSSHKeys              : (signature [Object], Function)
        getSSHKeys              : (signature Function)
        authenticateWithOauth   : (signature Object, Function)
        unregister              : (signature String, Function)
        finishRegistration      : (signature Object, Function) # DEPRECATED ~ GG
        verifyPassword          : (signature Object, Function)
        verifyByPin             : (signature Object, Function)

    schema          :
      username      :
        type        : String
        validate    : require('../name').validateName
        set         : (value) -> value.toLowerCase()
      oldUsername   : String
      uid           :
        type        : Number
        set         : Math.floor
      email         :
        type        : String
        validate    : require('../name').validateEmail
        set         : (value) -> value.toLowerCase()
      password      : String
      salt          : String
      blockedUntil  : Date
      blockedReason : String
      status        :
        type        : String
        enum        : [
          'invalid status type', [
            'unconfirmed','confirmed','blocked','deleted'
          ]
        ]
        default     : 'unconfirmed'
      passwordStatus:
        type        : String
        enum        : [
          'invalid password status type', [
            'needs reset', 'needs set', 'valid', 'autogenerated'
          ]
        ]
        default     : 'valid'
      registeredAt  :
        type        : Date
        default     : -> new Date
      registeredFrom:
        ip          : String
        country     : String
        region      : String
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
      foreignAuth            :
        github               :
          foreignId          : String
          username           : String
          token              : String
          firstName          : String
          lastName           : String
          email              : String
        odesk                :
          foreignId          : String
          token              : String
          accessTokenSecret  : String
          requestToken       : String
          requestTokenSecret : String
          profileUrl         : String
        facebook             :
          foreignId          : String
          username           : String
          token              : String
        linkedin             :
          foreignId          : String
    relationships       :
      ownAccount        :
        targetType      : JAccount
        as              : 'owner'
      leasedAccount     :
        targetType      : JAccount
        as              : 'leasor'

  sessions  = {}
  users     = {}
  guests    = {}

  @unregister = secure (client, toBeDeletedUsername, callback) ->
    {delegate} = client.connection

    console.log "#{delegate.profile.nickname} requested to delete: #{toBeDeletedUsername}"

    # deleter should be registered one
    if delegate.type is 'unregistered'
      return callback createKodingError "You are not registered!"

    if toBeDeletedUsername is "guestuser"
      return callback createKodingError "It's not allowed to delete this user!"

    # only owner and the dummy admins can delete a user
    unless toBeDeletedUsername is delegate.profile.nickname or
           delegate.can 'administer accounts'
      return callback createKodingError "You must confirm this action!"

    @createGuestUsername (err, username) =>
      return callback err  if err?
      email = "#{username}@koding.com"
      @one { username: toBeDeletedUsername }, (err, user) =>
        return callback err  if err?
        return callback createKodingError "User not found #{toBeDeletedUsername}"  unless user

        oldEmail = user.email

        userValues = {
          username
          email
          password        : createId()
          passwordStatus  : 'autogenerated'
          status          : 'deleted'
          registeredAt    : new Date 0
          lastLoginDate   : new Date 0
          onlineStatus    : 'offline'
          emailFrequency  : {}
          sshKeys         : []
          foreignAuth     : {}
        }
        modifier = { $set: userValues, $unset: { oldUsername: 1 }}
        # update the user with empty data
        user.update modifier, (err, docs) =>
          return callback err  if err?

          accountValues = {
            'profile.nickname'    : username
            'profile.firstName'   : 'a former'
            'profile.lastName'    : 'koding user'
            'profile.about'       : ''
            'profile.hash'        : getHash createId()
            'profile.avatar'      : ''
            'profile.experience'  : ''
            'profile.experiencePoints': 0
            'profile.lastStatusUpdate': ''
            type                  : 'deleted'
            ircNickame            : ''
            skillTags             : []
            locationTags          : []
            globalFlags           : ['deleted']
            onlineStatus          : 'offline'
          }

          JAccount.one {"profile.nickname": toBeDeletedUsername}, (err, account)=>
            return callback err  if err?
            return callback createKodingError "Account not found #{toBeDeletedUsername}"  unless account

            # update the account to be deleted with empty data
            account.update $set: accountValues, (err)=>
              return callback err  if err?
              JName.release toBeDeletedUsername, (err)=>
                return callback err  if err?
                JAccount.emit "UsernameChanged", {
                  oldUsername    : toBeDeletedUsername
                  isRegistration : false
                  username
                }

                user.unlinkOAuths =>

                  Payment = require "../payment"

                  deletedClient = connection: delegate: account

                  Payment.deleteAccount deletedClient, (err)=>

                    @logout deletedClient, (err) =>
                      callback err
                      Sendgrid.deleteUser oldEmail, ->


  @isRegistrationEnabled = (callback)->

    JRegistrationPreferences = require '../registrationpreferences'
    JRegistrationPreferences.one {}, (err, prefs)->
      callback err? or prefs?.isRegistrationEnabled or no


  @authenticateClient: (clientId, context, callback)->

    error = (message, rest...)->
      console.error "[JUser::authenticateClient] #{message}", rest...

    JSession.one { clientId }, (err, session)=>

      if err

        error "error finding session", { err, clientId }
        callback createKodingError err

      else unless session?

        JSession.createSession (err, { session, account })->

          if err?
            error "failed to create session", { err }
            return callback err
          else
            callback null, { session, account }

      else

        { username } = session

        unless username?

          error "no username found", { session }
          @logout clientId, (err)->

            callback createKodingError "no username found, logged out."

          return

        username = 'guestuser'  if /^guest-/.test username

        JUser.one {username}, (err, user)=>

          if err?

            error "error finding user with username", { err, username }
            callback createKodingError err

          else unless user?

            error "no user found with username", { username }
            @logout clientId, callback

          else

            user.fetchAccount context, (err, account)->

              if err?

                error "error fetching account", { context }
                callback createKodingError err

              else

                callback null, { session, account }


  getHash =(value)->
    require('crypto').createHash('md5').update(value.toLowerCase()).digest('hex')

  @whoami = secure ({connection:{delegate}}, callback)-> callback null, delegate

  checkBlockedStatus = (user, callback)->
    if user.status is 'blocked'
      if user.blockedUntil and user.blockedUntil > new Date
        toDate = user.blockedUntil.toUTCString()
        message = """
Account suspended due to violation of our acceptable use policy.

Hello,
This account has been put on suspension by Koding moderators due to a violation of our acceptable use policy. The ban will be in effect until #{toDate} at which time you will be able to log back in again. Should you have any questions regarding this ban, please write to ban@koding.com and allow 2-3 business days for us to research and reply. Even though your account is banned, all your data is safe and will be accessible once the ban lifts.

Please note, repeated violations of our acceptable use policy will result in the permanent deletion of your account.

Team Koding
          """
        callback createKodingError message
      else
        user.unblock callback
    else
      callback null

  @normalizeLoginId = (loginId, callback) ->
    if /@/.test loginId
      JUser.someData {email: loginId}, {username: 1}, (err, cursor) ->
        return callback err  if err

        cursor.nextObject (err, data) ->
          return callback err  if err?
          return callback { message: 'Unrecognized email' }  unless data?

          callback null, data.username
    else
      process.nextTick -> callback null, loginId

  @login$ = secure (client, credentials, callback) ->
    {sessionToken: clientId, connection} = client
    @login clientId, credentials, (err, response) ->
      return callback err  if err
      connection.delegate = response.account
      callback null, response


  @login = (clientId, credentials, callback)->
    { username: loginId, password } = credentials

    @normalizeLoginId loginId, (err, username) ->
      return callback err  if err

      constructor = this
      JSession.fetchSession clientId, (err, { session })->
        return callback err  if err
        unless session
          console.error "login: session not found", username
          return callback { message: "Couldn't restore your session!" }

        bruteForceControlData =
          ip        : session.clientIP
          username  : username
        # todo add alert support(mail, log etc)
        JLog.checkLoginBruteForce bruteForceControlData, (res)->
          unless res then return callback createKodingError "Your login access is blocked for #{JLog.timeLimit()} minutes."

          JUser.one { username }, (err, user)->
            if err
              logAndReturnLoginError username, err.message, callback
            # if user not found it means we dont know about given username
            else unless user?
              logAndReturnLoginError username, 'Unknown user name', callback
            # if password is autogenerated return error
            else if user.getAt('passwordStatus') is 'needs reset'
              logAndReturnLoginError username, 'You should reset your password in order to continue!', callback
            # hash of given password and given user's salt should match with user's password
            else unless user.getAt('password') is hashPassword password, user.getAt('salt')
              logAndReturnLoginError username, 'Access denied!', callback
            else
              afterLogin user, clientId, session, callback

  @verifyPassword = secure (client, options, callback)->
    {connection: {delegate}} = client
    {password, email} = options

    # handles error and decide to invalidate pin or not
    # depending on email and user variables
    handleError = (err, user) ->
      if email and user
        # when email and user is set, we need to invalidate verification token
        params =
          action    : "update-email"
          username  : user.username
          email     : email
        JVerificationToken = require '../verificationtoken'
        JVerificationToken.invalidatePin params, (err) ->
          return console.error 'Pin invalidation error occurred', err  if err
      callback err, no

    # fetch user for invalidating created token
    @fetchUser client, (err, user) ->
      return handleError err  if err
      if not password or password is ""
        return handleError createKodingError("Password cannot be empty!"), user
      confirmed = user.getAt('password') is hashPassword password, user.getAt('salt')
      return callback null, yes  if confirmed
      return handleError null, user


  verifyByPin: (options, callback)->

    if (@getAt 'status') is 'confirmed'
      return callback null

    JVerificationToken = require '../verificationtoken'

    {pin, resendIfExists} = options

    username = @getAt 'username'
    email    = @getAt 'email'

    options  = {
      user   : this
      action : 'verify-account'
      resendIfExists, pin, username, email
    }

    unless pin?

      JVerificationToken.requestNewPin options, (err)-> callback err

    else

      JVerificationToken.confirmByPin options, (err, confirmed)=>

        if err
          callback err
        else if confirmed
          @confirmEmail (err)-> callback err
        else
          callback createKodingError 'PIN is not confirmed.'


  @verifyByPin = secure (client, options, callback)->

    account = client.connection.delegate
    account.fetchUser (err, user)=>

      return callback new Error "User not found"  unless user

      user.verifyByPin options, callback



  logAndReturnLoginError = (username, error, callback)->
    JLog.log { type: "login", username: username, success: no }, ->
      callback createKodingError error



  checkUserStatus = (user, account, callback)->
    if user.status is 'unconfirmed' and KONFIG.emailConfirmationCheckerWorker.enabled
      error = createKodingError "You should confirm your email address"
      error.code = 403
      error.data or= {}
      error.data.name = account.profile.firstName or account.profile.nickname
      error.data.nickname = account.profile.nickname
      return callback error
    return callback null


  checkLoginConstraints = (user, account, callback)->
    checkBlockedStatus user, (err)->
      return callback err  if err
      checkUserStatus user, account, callback

  updateUserPasswordStatus = (user, callback)->
    # let user log in for the first time, than set password status
    # as 'needs reset'
    if user.passwordStatus is 'needs set'
        user.update {$set:passwordStatus:'needs reset'}, callback
    else
      callback null

  afterLogin = (user, clientId, session, callback)->
    user.fetchOwnAccount (err, account)->
      if err then return callback err
      checkLoginConstraints user, account, (err)->
        if err then return callback err
        updateUserPasswordStatus user, (err)->
          if err then return callback err
          replacementToken = createId()
          session.update {
            $set            :
              username      : user.username
              lastLoginDate : new Date
              clientId      : replacementToken
            $unset:
              guestId       : 1
          }, (err)->
              return callback err  if err
              user.update { $set: lastLoginDate: new Date }, (err) ->
                return callback err  if err
                JAccount.emit "AccountAuthenticated", account
                # This should be called after login and this
                # is not correct place to do it, FIXME GG
                # p.s. we could do that in workers
                JLog.log { type: "login", username: account.username, success: yes }, ->
                account.updateCounts()
                JUser.clearOauthFromSession session, ->
                  callback null, {account, replacementToken}
                  # options = targetOptions: selector: tags: $in: ["nosync"]
                  # account.fetchSubscriptions {}, options, (err, subscriptions) ->
                  #   console.warn err  if err
                  #   if subscriptions.length is 0
                  #     JPaymentSubscription.createFreeSubscription account, (err, subscription) ->
                  #       console.warn err  if err
                  #       subscription.debitPack tag: "vm", (err) ->
                  #         console.warn "VM pack couldn't be debited from subscription: #{err}"  if err

  @logout = secure (client, callback)->
    if 'string' is typeof client
      sessionToken = client
    else
      {sessionToken} = client
      delete client.connection.delegate
      delete client.sessionToken

    # if sessionToken doesnt exist, safe to return
    return callback null unless sessionToken

    JSession.remove { clientId: sessionToken }, callback

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
          if err or !invite?
            callback createKodingError 'Invalid invitation ID!'
          else
            callback null, { isEligible: yes, invite }
      else
        callback null, isEligible: yes

  @addToGroup = (account, slug, email, invite, callback)->
    JGroup.one {slug}, (err, group)->
      return callback err if err or not group
      if invite
        invite.redeem account, (err) ->
          return callback err if err
          group.approveMember account, callback
      else
        group.approveMember account, callback

  @addToGroups = (account, invite, email, callback)->
    @addToGroup account, 'koding', email, null, (err)=>
      if err then callback err
      else if invite?.group and invite.group isnt 'koding'
        @addToGroup account, invite.group, email, invite, callback
      else
        callback null


  @createGuestUsername = (callback) ->

    callback null, "guest-#{rack()}"


  @fetchGuestUser = (callback)->

    @createGuestUsername (err, username) =>

      return callback err  if err?

      JUser.one 'username': 'guestuser', (err, user) =>

        return callback err  if err?

        user.username = username
        user.password = createId()
        user.email    = "#{username}@koding.com"

        user.fetchOwnAccount (err, account) =>
          return callback err  if err?

          account.profile.nickname = username

          @configureNewAcccount account, user, createId(), callback


  @createUser = (userInfo, callback)->
    { username, email, password, passwordStatus, firstName, lastName, foreignAuth,
      silence } = userInfo

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
          passwordStatus: passwordStatus or 'valid'
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
            groupJoined    : on
            groupLeft      : off
            mention        : on
            marketing      : on
          }
        }

        user.foreignAuth = foreignAuth  if foreignAuth

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
            account.save (err)=>
              if err then callback err
              else user.addOwnAccount account, (err) ->
                return callback err  if err
                callback null, user, account

  @configureNewAcccount = (account, user, replacementToken, callback) ->
    JUser.emit 'UserCreated', user
    JAccount.emit "AccountAuthenticated", account
    callback null, {account, replacementToken}

  @fetchUserByProvider = (provider, session, callback)->
    {foreignAuth} = session
    unless foreignAuth
      return callback createKodingError "No foreignAuth:#{provider} info in session"

    query                                      = {}
    query["foreignAuth.#{provider}.foreignId"] = foreignAuth[provider].foreignId

    JUser.one query, callback

  @authenticateWithOauth = secure (client, resp, callback)->
    {isUserLoggedIn, provider} = resp
    {sessionToken} = client
    JSession.one {clientId: sessionToken}, (err, session) =>
      return callback createKodingError err  if err

      unless session
        {connection: {delegate: {profile: {nickname}}}} = client
        console.error "authenticateWithOauth: session not found", nickname

        return callback createKodingError "Couldn't restore your session!"

      kallback = (err, resp={}) ->
        {account, replacementToken} = resp
        callback err, {
          isNewUser : false
          userInfo  : null
          account
          replacementToken
        }
      @fetchUserByProvider provider, session, (err, user) =>
        return callback createKodingError err.message  if err
        if isUserLoggedIn
          if user
            @clearOauthFromSession session, ->
              callback createKodingError """
                Account is already linked with another user.
              """
          else
            @fetchUser client, (err, user)=>
              @persistOauthInfo user.username, sessionToken, kallback
        else
          if user
            afterLogin user, sessionToken, session, kallback
          else
            info = session.foreignAuth[provider]
            {username, email, firstName, lastName} = info
            callback null, {
              isNewUser : true,
              userInfo  : {username, email, firstName, lastName}
            }


  @validateAll = (userFormData, callback)=>

    validator  = require './validators'

    isError    = no
    errors     = {}
    queue      = []

    (key for key of validator).forEach (field)=>

      queue.push => validator[field].call this, userFormData, (err)->

        if err?
          errors[field] = err
          isError = yes

        queue.fin()

    dash queue, ->

      callback if isError
        { message: "Errors were encountered during validation", errors }
      else null


  @changePasswordByUsername = (username, password, callback) ->
    salt = createSalt()
    hashedPassword = hashPassword password, salt
    @one { username }, (err, user) ->
      return callback err if err
      return callback new Error "User not found" unless user
      user.changePassword password, callback

  @changeEmailByUsername = (options, callback) ->
    { account, oldUsername, email } = options
    # prevent from leading and trailing spaces
    email = email.trim()
    @update { username: oldUsername }, { $set: { email }}, (err, res)=>
      return callback err  if err
      account.profile.hash = getHash email
      account.save (err)-> console.error if err
      callback null

  @changeUsernameByAccount = (options, callback)->
    { account, username, clientId, isRegistration } = options
    account.changeUsername { username, isRegistration }, (err) =>
      return callback err   if err?
      return callback null  unless clientId?
      newToken = createId()
      JSession.one { clientId }, (err, session) =>
        if err?
          return callback createKodingError "Could not update your session"

        if session?
          session.update { $set: { clientId: newToken, username }}, (err) ->
            return callback err  if err?
            callback null, newToken
        else
          callback createKodingError "Session not found!"

  @removeFromGuestsGroup = (account, callback) ->
    JGroup.one { slug: 'guests' }, (err, guestsGroup) ->
      return callback err  if err?
      return callback message: "Guests group not found!"  unless guestsGroup?
      guestsGroup.removeMember account, callback

  @convert = secure (client, userFormData, callback) ->
    { connection, sessionToken : clientId, clientIP } = client
    { delegate : account } = connection
    { nickname : oldUsername } = account.profile
    { username, email, firstName, lastName, agree,
      inviteCode, referrer, password, passwordConfirm } = userFormData

    if not firstName or firstName is "" then firstName = username
    if not lastName then lastName = ""

    # only unreigstered accounts can be "converted"
    if account.status is "registered"
      return callback createKodingError "This account is already registered."

    if /^guest-/.test username
      return callback createKodingError "Reserved username!"

    if username is "guestuser"
      return callback createKodingError "Reserved username."

    if password isnt passwordConfirm
      return callback createKodingError "Passwords must match!"

    if clientIP
      { ip, country, region } = Regions.findLocation clientIP

    newToken       = null
    invite         = null
    user           = null
    quotaExceedErr = null
    error          = null

    aNewRegister   = oldUsername is 'guestuser'

    queue = [
      =>
        @validateAll userFormData, (err) =>
          return callback err  if err
          queue.next()

      =>
        if aNewRegister

          userInfo = { username, firstName, lastName, email, password }

          @createUser userInfo, (err, _user, _account)=>
            return callback err  if err

            if _user? and _account?

              [account, user] = [_account, _user]
              queue.next()

            else

              return callback createKodingError "Failed to create user!"

        else
          queue.next()

      =>
        if not aNewRegister and username? and email?
          options = { account, oldUsername, email, username }
          @changeEmailByUsername options, (err) =>
            return callback err  if err
            queue.next()
        else
          queue.next()

      ->
        if not aNewRegister
          account.fetchUser (err, user_) ->
            return callback err  if err
            user = user_
            queue.next()
        else
          queue.next()

      ->
        if ip? and country? and region?
          locationModifier = $set    :
            "registeredFrom.ip"      : ip
            "registeredFrom.country" : country
            "registeredFrom.region"  : region
          user.update locationModifier, -> queue.next()
        else
          queue.next()

      =>
        oauthUser = if aNewRegister then username else oldUsername

        @persistOauthInfo oauthUser, client.sessionToken, (err)=>
          return callback err  if err
          queue.next()

      =>
        if aNewRegister and username?
          options = { account, username, clientId, isRegistration: yes }
          @changeUsernameByAccount options, (err, newToken_) =>
            return callback err  if err
            newToken = newToken_
            queue.next()
        else
          queue.next()

      =>
        @verifyEnrollmentEligibility {email: user.email, inviteCode}, (err, { isEligible, invite: invite_ }) =>
          return callback err  if err
          invite = invite_
          queue.next()

      =>
        @addToGroups account, invite, user.email, (err) =>
          error = err
          queue.next()

      ->
        account.update $set: type: 'registered', (err) ->
          return callback err  if err?
          queue.next()

      ->
        user.setPassword password, (err) ->
          return callback err  if err?
          queue.next()

      ->
        # Auto confirm accounts for development environment
        # This config should be no for production! ~ GG
        if KONFIG.autoConfirmAccounts
          user.confirmEmail (err)->
            console.warn err  if err?
            queue.next()
        else
          user.verifyByPin resendIfExists: yes, (err)->
            console.warn "Failed to send verification token:", err  if err
            queue.next()

      ->
        JAccount.emit "AccountRegistered", account, referrer
        queue.next()

      ->
        callback error, {account, newToken}
        queue.next()

      ->
        # rest are 3rd party api calls, not important to block register

        SiftScience = require "../siftscience"
        SiftScience.createAccount client, referrer, ->

        queue.next()

      ->

        Sendgrid.addNewUser user.email, user.username, ->
        queue.next()

    ]

    daisy queue


  # DEPRECATED
  @finishRegistration: secure (client, formData, callback) ->
    { sessionToken: clientId, clientIP } = client
    console.warn "DEPRECATED JUser::finishRegistration called from", \
                 { clientIP, sessionToken }
    callback null


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

  @changePassword = secure (client, password, callback) ->
    @fetchUser client, (err,user)->
      return callback createKodingError "Something went wrong please try again!" if err or not user
      if user.getAt('password') is hashPassword password, user.getAt('salt')
        return callback createKodingError "PasswordIsSame"

      user.changePassword password, (err)=>
        sendChangeEmail user.email, "password"
        return callback err

  sendChangeEmail = (email, type)->
    email = new JMail {
      email
      subject : "Your #{type} has been changed"
      content : """
        Your #{type} has been changed!  If you didn't request this change, please contact support@koding.com immediately!
      """
    }
    email.save()

  @changeEmail = secure (client,options,callback)->

    {email} = options

    account = client.connection.delegate
    account.fetchUser (err, user)=>
      return callback createKodingError "Something went wrong please try again!" if err
      if email is user.email then return callback createKodingError "EmailIsSameError"
      @emailAvailable email, (err, res)=>
        return callback createKodingError "Something went wrong please try again!" if err
        if res is no
          callback createKodingError "Email is already in use!"
        else
          user.changeEmail account, options, callback
          if account.status is 'registered'
            # don't send an email when guests change their emails, which we
            # need to allow for the pricing workflow.
            sendChangeEmail user.email, "email"

  @emailAvailable = (email, callback)->
    @count {email}, (err, count)->
      if err
        callback err
      else if count is 1
        callback null, no
      else
        callback null, yes

  @usernameAvailable = (username, callback)->
    JName = require '../name'

    username += ''
    res =
      kodingUser   : no
      forbidden    : yes

    JName.count { name: username }, (err, count)=>
      if err or username.length < 4 or username.length > 25
        callback err, res
      else
        res.kodingUser = if count is 1 then yes else no
        res.forbidden = if username in @bannedUserList then yes else no
        callback null, res


  fetchAccount:(context, rest...)->
    @fetchOwnAccount rest...

  setPassword:(password, callback)->
    salt = createSalt()
    @update $set: {
      salt
      password       : hashPassword password, salt
      passwordStatus : 'valid'
    }, callback


  changePassword:(newPassword, callback)->

    @setPassword newPassword, (err)->
      return callback err  if err?
      sendChangeEmail @email, "password"
      callback null

  changeEmail:(account, options, callback)->

    JVerificationToken = require '../verificationtoken'

    {email, pin} = options

    if account.type is 'unregistered'
      @update $set: { email }, (err) ->
        return callback err  if err

        callback null
      return

    if not pin
      options =
        action    : "update-email"
        user      : this
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

  fetchHomepageView:(options, callback)->
    {account, bongoModels} = options
    @fetchAccount 'koding', (err, account)->
      if err then callback err
      else account.fetchHomepageView options, callback

  confirmEmail: (callback)->
    @update {$set: status: 'confirmed'}, (err, res)=>
      return callback err if err
      JUser.emit "EmailConfirmed", @

      welcomeemail = require "../welcomeemail"
      welcomeemail.send @email, @username, (err)->
        callback err


  block:(blockedUntil, callback)->
    unless blockedUntil then return callback createKodingError "Blocking date is not defined"
    @update
      $set:
        status: 'blocked',
        blockedUntil : blockedUntil
    , (err) =>
        return callback err if err
        JUser.emit "UserBlocked", @
        # clear all of the cookies of the blocked user

        console.log "JUser#block JSession#remove", {@username, blockedUntil}

        JSession.remove {username: @username}, callback

  unblock:(callback)->
    @update
      $set            :
        blockedUntil  : new Date()
    , (err) =>
      return callback err if err

      JUser.emit "UserUnblocked", @
      return callback err

  unlinkOAuths: (callback)->
    @update $unset: {foreignAuth:1, foreignAuthType:1}, (err)=>
      return callback err  if err
      @fetchOwnAccount (err, account)->
        return callback err  if err
        account.unstoreAll callback

  @persistOauthInfo: (username, clientId, callback)->
    @extractOauthFromSession clientId, (err, foreignAuthInfo)=>
      return callback err   if err
      return callback null  unless foreignAuthInfo
      return callback null  unless foreignAuthInfo.session

      @saveOauthToUser foreignAuthInfo, username, (err)=>
        return callback err  if err
        @clearOauthFromSession foreignAuthInfo.session, (err)=>
          return callback err  if err
          @copyPublicOauthToAccount username, foreignAuthInfo, callback

  @extractOauthFromSession: (clientId, callback)->
    JSession.one {clientId: clientId}, (err, session)->
      return callback err   if err
      return callback null  unless session

      {foreignAuth, foreignAuthType} = session
      if foreignAuth and foreignAuthType
        callback null, {foreignAuth, foreignAuthType, session}
      else
        callback null # WARNING: don't assume it's an error if there's no foreignAuth

  @saveOauthToUser: ({foreignAuth, foreignAuthType}, username, callback)->
    query = {}
    query["foreignAuth.#{foreignAuthType}"] = foreignAuth[foreignAuthType]

    @update {username}, $set: query, callback

  @clearOauthFromSession: (session, callback)->
    session.update $unset: {foreignAuth:1, foreignAuthType:1}, callback

  @copyPublicOauthToAccount: (username, {foreignAuth, foreignAuthType}, callback)->
    JAccount.one {"profile.nickname":username}, (err, account)->
      return callback err  if err

      name    = "ext|profile|#{foreignAuthType}"
      content = foreignAuth[foreignAuthType].profile
      account._store {name, content}, callback

  @setSSHKeys: secure (client, sshKeys, callback)->
    @fetchUser client, (err,user)->
      user.sshKeys = sshKeys
      user.save callback

  @getSSHKeys: secure (client, callback)->
    @fetchUser client, (err,user)->
      callback user.sshKeys or []
