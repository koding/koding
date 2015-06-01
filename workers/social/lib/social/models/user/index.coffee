jraphical   = require 'jraphical'
Regions     = require 'koding-regions'
{argv}      = require 'optimist'
KONFIG      = require('koding-config-manager').load("main.#{argv.c}")
Flaggable   = require '../../traits/flaggable'
KodingError = require '../../error'
{ extend, uniq }  = require 'underscore'

module.exports = class JUser extends jraphical.Module
  {secure, signature, daisy, dash} = require 'bongo'

  JAccount             = require '../account'
  JSession             = require '../session'
  JInvitation          = require '../invitation'
  JName                = require '../name'
  JGroup               = require '../group'
  JLog                 = require '../log'
  JPaymentPlan         = require '../payment/plan'
  JPaymentSubscription = require '../payment/subscription'
  ComputeProvider      = require '../computeproviders/computeprovider'
  Email                = require '../email'

  { v4: createId } = require 'node-uuid'
  {Relationship}   = jraphical

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
                     'landing','hello','dev', 'sandbox', 'latest']


  hashPassword = (value, salt)->
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
    {nickname} = delegate.profile

    console.log "#{nickname} requested to delete: #{toBeDeletedUsername}"

    # deleter should be registered one
    if delegate.type is 'unregistered'
      return callback createKodingError "You are not registered!"

    # only owner and the dummy admins can delete a user
    unless toBeDeletedUsername is nickname or
           delegate.can 'administer accounts'
      return callback createKodingError "You must confirm this action!"

    username = @createGuestUsername()

    # Adding -rm suffix to separate them from real guests
    # -rm was intentional otherwise we are exceeding the max username length
    username = "#{username}-rm"

    email = "#{username}@koding.com"
    @one { username: toBeDeletedUsername }, (err, user) =>
      return callback err  if err?

      unless user
        return callback createKodingError \
          "User not found #{toBeDeletedUsername}"

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

          unless account
            return callback createKodingError \
              "Account not found #{toBeDeletedUsername}"

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

                  @logout deletedClient, callback


  @isRegistrationEnabled = (callback)->

    JRegistrationPreferences = require '../registrationpreferences'
    JRegistrationPreferences.one {}, (err, prefs)->
      callback err? or prefs?.isRegistrationEnabled or no


  @authenticateClient: (clientId, callback)->

    logError = (message, rest...) ->
      console.error "[JUser::authenticateClient] #{message}", rest...

    logout = (reason, clientId, callback) =>

      @logout clientId, (err)->
        logError reason, clientId
        callback createKodingError reason

    # Let's try to lookup provided session first
    JSession.one { clientId }, (err, session)=>

      if err

        # This is a very rare state here
        logError "error finding session", { err, clientId }
        callback createKodingError err

      else unless session?

        # We couldn't find the session with given token
        # so we are creating a new one now.
        JSession.createSession (err, { session, account })->

          if err?
            logError "failed to create session", { err }
            callback err
          else

            # Voila session created and sent back, scenario #1
            callback null, { session, account }

      else

        # So we have a session, let's check it out if its a valid one
        { username } = session

        unless username?

          # A session without a username is nothing, let's kill it
          # and logout the user, this is also a rare condition
          logout "no username found", clientId, callback

          return

        # If we are dealing with a guest session we know that we need to
        # use fake guest user

        if /^guest-/.test username
          JUser.fetchGuestUser (err, response) ->
            return logout "error fetching guest account"  if err

            {account} = response
            return logout "guest account not found"  if not response?.account

            return callback null, {account, session}

          return

        JUser.one {username}, (err, user)=>

          if err?

            logout "error finding user with username", clientId, callback

          else unless user?

            logout "no user found with #{username} and sessionId", clientId, callback

          else

            context = { group: session?.groupName ? 'koding' }

            user.fetchAccount context, (err, account)->

              if err?
                logout "error fetching account", clientId, callback

              else

                # A valid session, a valid user attached to
                # it voila, scenario #2
                callback null, { session, account }


  @getHash = getHash = (value) ->
    require('crypto').createHash('md5').update(value.toLowerCase()).digest('hex')

  @whoami = secure ({connection:{delegate}}, callback)-> callback null, delegate

  checkBlockedStatus = (user, callback)->
    if user.status is 'blocked'
      if user.blockedUntil and user.blockedUntil > new Date
        toDate = user.blockedUntil.toUTCString()
        message = """
          Account suspended due to violation of our acceptable use policy.

          Hello,

          This account has been put on suspension by Koding moderators due
          to a violation of our acceptable use policy. The ban will be in
          effect until #{toDate} at which time you will be able to log back
          in again. Should you have any questions regarding this ban, please
          write to ban@koding.com and allow 2-3 business days for us to
          research and reply. Even though your account is banned, all your
          data is safe and will be accessible once the ban lifts.

          Please note, repeated violations of our acceptable use policy
          will result in the permanent deletion of your account.

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

    { username: loginId, password, groupName, invitationToken } = credentials

    bruteForceControlData = {}
    session               = null
    username              = null
    user                  = null
    account               = null
    invitation            = null
    groupName            ?= 'koding'

    queue = [ =>
      @normalizeLoginId loginId, (err, username_) ->
        return callback err  if err

        username = username_

        queue.next()
    , ->
      # fetch session of the current requester
      JSession.fetchSession clientId, (err, { session: fetchedSession })->
        return callback err  if err

        session = fetchedSession
        unless session
          console.error "login: session not found", username
          return callback { message: "Couldn't restore your session!" }

        bruteForceControlData =
          ip        : session.clientIP
          username  : username

        queue.next()

    , ->
      # todo add alert support(mail, log etc)
      JLog.checkLoginBruteForce bruteForceControlData, (res) ->

        unless res
          return callback createKodingError \
            "Your login access is blocked for #{JLog.timeLimit()} minutes."

        queue.next()
    , ->
      # check credential validity
      JUser.one { username }, (err, user_) ->

        user = user_

        return logAndReturnLoginError username, err.message, callback if err

        # if user not found it means we dont know about given username
        return logAndReturnLoginError username, 'Unknown user name', callback  unless user?

        # if password is autogenerated return error
        if user.getAt('passwordStatus') is 'needs reset'
          return logAndReturnLoginError username, \
            'You should reset your password in order to continue!', callback

        # hash of given password and given user's salt should match with user's password
        unless user.getAt('password') is hashPassword password, user.getAt('salt')
          return logAndReturnLoginError username, 'Access denied!', callback

        # if everything is fine, just continue
        queue.next()

    , ->
      # fetch account of the user, we will use it later
      JAccount.one { "profile.nickname": username }, (err, account_)->
        return callback { message: "couldn't find account!" }  if err
        account = account_
        queue.next()

    , =>
      # check if user can access to group
      #
      # there can be two cases here
      # # user is member, check validity
      # # user is not member, and trying to access with invitationToken
      # both should succeed

      # if we dont have an invitation code, do not continue
      return queue.next()  unless invitationToken

      JInvitation = require '../invitation'
      JInvitation.byCode invitationToken, (err, invitation_) =>
        return callback err  if err
        return callback { message: "invitation is not valid" }  unless invitation_
        invitation = invitation_
        queue.next()

    , =>
      # check if user has pending invitation
      return queue.next()  if invitationToken

      JInvitation = require '../invitation'
      options = { email: user.email, groupName }
      JInvitation.one options, {}, (err, invitation_) =>
        invitation = invitation_ if invitation_
        queue.next()

    , =>
      # check for membership
      JGroup.one { slug: groupName }, (err, group) =>
        if not group or err
          return callback { message: "group doesnt exist"}

        group.isMember account, (err , isMember)=>
          return callback err  if err
          return queue.next()  if isMember # if user is already member, we can continue

          # addGroup will check all prerequistes about joining to a group
          @addToGroup account, groupName, user.email, invitation, (err) ->
            return callback err  if err
            return queue.next()
    , ->
      # we are sure that user can access to the group, set group name into
      # cookie while logging in
      session.update { $set : {groupName} }, (err) ->
        return callback err  if err
        queue.next()

    , =>
      # continue login
      afterLogin user, clientId, session, (err, response) ->
        callback err, response
        queue.next()  unless err
    ]

    daisy queue


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

              # This should be called after login and this
              # is not correct place to do it, FIXME GG
              # p.s. we could do that in workers
              account.updateCounts()

              JLog.log
                type: "login", username: account.username, success: yes

              JUser.clearOauthFromSession session, ->
                callback null, { account, replacementToken }


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

  @verifyEnrollmentEligibility = (options, callback) ->
    { email, invitationToken, groupName } = options

    # this is legacy but still in use, just checks if registeration is enabled or not
    JRegistrationPreferences = require '../registrationpreferences'
    JInvitation = require '../invitation'
    JRegistrationPreferences.one {}, (err, prefs)->

      return callback err  if err
      unless prefs.isRegistrationEnabled
        return callback new Error 'Registration is currently disabled!'

      # check if user's email domain is in allowed domains
      checkWithDomain = (groupName, email, callback) ->
        JGroup.one { slug: groupName }, (err, group) =>
          return callback err  if err
          # yes weird, but we are creating user before creating group
          return callback null, { isEligible: yes } if not group

          isAllowed = group.isInAllowedDomain email
          return callback createKodingError "Your email domain is not in allowed \
            domains for this group"  unless isAllowed

          return callback null, { isEligible: yes }

      # check if email domain is in allowed domains
      return checkWithDomain groupName, email, callback  if not invitationToken

      JInvitation.byCode invitationToken, (err, invitation) ->
        # check if invitation exists
        if err or !invitation?
          return callback createKodingError 'Invalid invitation code!'

        # check if invitation is valid
        if invitation.isValid() and  invitation.groupName is groupName
          return callback null, { isEligible: yes, invitation }

        # last resort, check if email domain is under allowed domains
        return checkWithDomain groupName, email, callback

  @addToGroup = (account, slug, email, invitation, callback) ->
    options = { email: email, groupName: slug }
    options.invitationToken = invitation.code if invitation?.code

    JUser.verifyEnrollmentEligibility options, (err, res) ->
      return callback err  if err
      return callback createKodingError 'malformed response' if not res
      return callback createKodingError 'can not join to group' if not res.isEligible

      # fetch group that we are gonna add account in
      JGroup.one { slug }, (err, group) ->
        return callback err   if err
        return callback null  if not group

        group.approveMember account, (err) ->
          return callback err  if err

          # do not forget to redeem invitation
          return invitation.accept account, callback  if invitation

          JInvitation.one { email, groupName : slug }, (err, invitation) ->
            # if we got error or invitation doesnt exist, just return
            return callback null if err or not invitation
            return invitation.accept account, callback

  @addToGroups = (account, slugs, email, invitation, callback) ->
    slugs.push invitation.groupName if invitation?.groupName
    slugs = uniq slugs # clean up slugs
    queue = slugs.map (slug) =>=>
      @addToGroup account, slug, email, invitation, (err) ->
        return callback err  if err
        queue.fin()

    dash queue, callback

  @createGuestUsername = -> "guest-#{rack()}"


  @fetchGuestUser = (callback)->

    username      = @createGuestUsername()

    account = new JAccount()
    account.profile = {nickname: username}
    account.type = 'unregistered'

    callback null, { account, replacementToken: createId() }


  @createUser = (userInfo, callback)->

    { username, email, password, passwordStatus,
      firstName, lastName, foreignAuth, silence, emailFrequency } = userInfo

    emailFrequencyDefaults = {
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

    # _.defaults doesnt handle undefined, extend handles correctly
    emailFrequency = extend emailFrequencyDefaults, emailFrequency

    slug =
      slug            : username
      constructorName : 'JUser'
      usedAsPath      : 'username'
      collectionName  : 'jUsers'

    JName.claim username, [slug], 'JUser', (err) ->

      return callback err  if err

      salt = createSalt()
      user = new JUser {
        username
        email
        salt
        password         : hashPassword password, salt
        passwordStatus   : passwordStatus or 'valid'
        emailFrequency   : emailFrequency
      }

      user.foreignAuth = foreignAuth  if foreignAuth

      user.save (err)->

        return  if err
          if err.code is 11000
          then callback createKodingError "Sorry, \"#{email}\" is already in use!"
          else callback err

        account      = new JAccount
          profile    : {
            nickname : username
            hash     : getHash email
            firstName
            lastName
          }

        account.save (err)->

          if err then callback err
          else user.addOwnAccount account, (err) ->
            if err then callback err
            else callback null, user, account


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
            @fetchUser client, (err, user) =>
              return callback createKodingError err.message  if err
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
    { account, username, clientId, isRegistration, groupName } = options
    account.changeUsername { username, isRegistration }, (err) =>
      return callback err   if err?
      return callback null  unless clientId?
      newToken = createId()
      JSession.one { clientId }, (err, session) =>
        if err?
          return callback createKodingError "Could not update your session"

        if session?
          session.update { $set: { clientId: newToken, username, groupName }}, (err) ->
            return callback err  if err?
            callback null, newToken
        else
          callback createKodingError "Session not found!"

  @removeFromGuestsGroup = (account, callback) ->
    JGroup.one { slug: 'guests' }, (err, guestsGroup) ->
      return callback err  if err?
      return callback message: "Guests group not found!"  unless guestsGroup?
      guestsGroup.removeMember account, callback

  createGroupStack = (account, groupName, callback)->
    _client =
      connection : delegate : account
      context    : group    : groupName

    ComputeProvider.createGroupStack _client, (err)->
      if err?
        console.warn "Failed to create group stack for #{account.profile.nickname}:", err

      # We are not returning error here on purpose, even stack template
      # not created for a user we don't want to break registration process
      # at all ~ GG
      callback()

  @convert = secure (client, userFormData, callback) ->

    { connection, sessionToken : clientId, clientIP } = client
    { delegate : account } = connection
    { nickname : oldUsername } = account.profile
    { username, email, firstName, lastName, agree,
      invitationToken, referrer, password, passwordConfirm,
      emailFrequency } = userFormData

    if not firstName or firstName is "" then firstName = username
    if not lastName then lastName = ""

    # only unreigstered accounts can be "converted"
    if account.type is "registered"
      return callback createKodingError "This account is already registered."

    if /^guest-/.test username
      return callback createKodingError "Reserved username!"

    if username is "guestuser"
      return callback createKodingError "Reserved username: 'guestuser'!"

    if password isnt passwordConfirm
      return callback createKodingError "Passwords must match!"

    if clientIP
      { ip, country, region } = Regions.findLocation clientIP

    newToken       = null
    invitation     = null
    user           = null
    quotaExceedErr = null
    error          = null

    # TODO this can cause problems
    aNewRegister   = yes

    queue = [
      =>
        @extractOauthFromSession client.sessionToken, (err, foreignAuthInfo)=>
          console.log "Error while getting oauth data from session", err  if err

          # Password is not required for GitHub users since they are authorized via GitHub.
          # To prevent having the same password for all GitHub users since it may be
          # a security hole, let's auto generate it if it's not provided in request
          if foreignAuthInfo?.foreignAuthType and not password?
            password        = userFormData.password        = createId()
            passwordConfirm = userFormData.passwordConfirm = password

          queue.next()

      =>
        @validateAll userFormData, (err) =>
          return callback err  if err
          queue.next()

      =>
        @emailAvailable email, (err, res)=>
          if err
            return callback createKodingError "Something went wrong"

          if res is no
            return callback createKodingError "Email is already in use!"
          else
            queue.next()

      =>
        # check if user can register to regarding group
        options =
          email           : email
          invitationToken : invitationToken
          groupName       : client.context.group

        @verifyEnrollmentEligibility options, (err, res) =>
          return callback err  if err

          { isEligible, invitation: invitation_ } = res

          if not isEligible
            return callback new Error "you can not register to #{client.context.group}"

          invitation = invitation_
          queue.next()

      =>
        if aNewRegister

          userInfo = { username, firstName, lastName,
            email, password, emailFrequency }

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
          options = {
            account        : account
            username       : username
            clientId       : clientId
            isRegistration : yes
            groupName      : client.context.group
          }

          @changeUsernameByAccount options, (err, newToken_) =>
            return callback err  if err
            newToken = newToken_
            queue.next()
        else
          queue.next()

      =>
        groupNames = [client.context.group, 'koding']

        @addToGroups account, groupNames, user.email, invitation, (err) =>
          error = err
          queue.next()
      ->
        # create default stack for koding group, when a user joins this is only
        # required for koding group, not neeed for other teams
        _client =
          connection : delegate : account
          context    : group    : 'koding'

        ComputeProvider.createGroupStack _client, (err)->
          if err?
            console.warn "Failed to create group stack for #{account.profile.nickname}:", err

          # We are not returning error here on purpose, even stack template
          # not created for a user we don't want to break registration process
          # at all ~ GG
          queue.next()
      ->
        account.update $set: type: 'registered', (err) ->
          return callback err  if err?
          queue.next()

      ->
        account.createSocialApiId (err) ->
          return callback err  if err
          queue.next()
      ->
        return queue.next()  unless referrer

        if username is referrer
          console.error "User (#{username}) tried to refer themself."
          return queue.next()

        JUser.count {username: referrer}, (err, count)->
          if err? or count < 1
            console.error "Provided referrer not valid:", err
            return queue.next()

          account.update $set: { referrerUsername: referrer }, (err)->

            if err?
            then console.error err
            else console.log "#{referrer} referred #{username}"

            queue.next()

      ->
        user.setPassword password, (err) ->
          return callback err  if err?
          queue.next()

      ->
        JUser.emit "UserRegistered", {user, account}
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
        callback error, {account, newToken}
        queue.next()

      ->
        # don't block register

        {username, email} = user
        subject           = Email.types.WELCOME
        Email.queue username, { to : email, subject }, {}, ->

        queue.next()

      ->
        SiftScience = require "../siftscience"
        SiftScience.createAccount client, referrer, ->

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
      return callback err  if err

      noUserError = createKodingError \
        "No user found! Not logged in or session expired"

      if not session or not session.username
        return callback noUserError

      JUser.one username: session.username, (err, user)->

        if err or not user
          console.log "[JUser::fetchUser]", err  if err?
          callback noUserError
        else
          callback null, user


  @changePassword = secure (client, password, callback) ->

    @fetchUser client, (err, user)->

      if err or not user
        return callback createKodingError \
          "Something went wrong please try again!"

      if user.getAt('password') is hashPassword password, user.getAt('salt')
        return callback createKodingError "PasswordIsSame"

      user.changePassword password, (err)-> callback err


  sendChangedEmail = (username, firstName, to, type, callback) ->

    subject = if type is 'email' then Email.types.EMAIL_CHANGED
    else Email.types.PASSWORD_CHANGED

    Email.queue username, {to, subject}, {firstName}, callback


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


  @emailAvailable = (email, callback)->
    unless typeof email is 'string'
      return callback createKodingError 'Not a valid email!'

    @count {email}, (err, count)-> callback err, count is 0


  @usernameAvailable = (username, callback)->
    JName = require '../name'

    username += ''
    res =
      kodingUser : no
      forbidden  : yes

    JName.count { name: username }, (err, count)=>

      if err or username.length < 4 or username.length > 25
        callback err, res
      else
        res.kodingUser = count is 1
        res.forbidden  = username in @bannedUserList
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


  changePassword: (newPassword, callback)->

    @setPassword newPassword, (err)=>
      return callback err  if err

      @fetchAccount 'koding', (err, account)=>
        return callback err  if err

        {firstName} = account.profile
        sendChangedEmail @getAt('username'), firstName, @getAt('email'), 'password', callback


  changeEmail:(account, options, callback)->

    JVerificationToken = require '../verificationtoken'

    {email, pin} = options

    if account.type is 'unregistered'
      @update $set: { email }, (err) ->
        return callback err  if err

        callback null
      return

    action = "update-email"

    if not pin

      options = {
        email, action, user: this, resendIfExists: yes
      }

      JVerificationToken.requestNewPin options, callback

    else
      options = {
        email, action, pin, username: @getAt 'username'
      }

      JVerificationToken.confirmByPin options, (err, confirmed)=>

        return callback err  if err

        unless confirmed
          return callback createKodingError 'PIN is not confirmed.'

        oldEmail = @getAt 'email'

        @update $set: {email}, (err, res)=>
          return callback err  if err

          account.profile.hash = getHash email
          account.save (err)=>
            return callback err  if err

            {firstName} = account.profile

            # send EmailChanged event
            @constructor.emit 'EmailChanged', {
              username: @getAt('username')
              oldEmail: oldEmail
              newEmail: email
            }

            sendChangedEmail @getAt('username'), firstName, oldEmail, 'email', callback


  fetchHomepageView:(options, callback)->
    {account, bongoModels} = options
    @fetchAccount 'koding', (err, account)->
      if err then callback err
      else account.fetchHomepageView options, callback


  confirmEmail: (callback)->

    status = @getAt 'status'

    # for some reason status is sometimes 'undefined', so check for that
    if status? and status isnt 'unconfirmed'
      console.log "ALERT: #{@getAt 'username'} is trying to confirm '#{status}' email"
      return callback null

    @update {$set: status: 'confirmed'}, (err, res)=>
      return callback err if err
      JUser.emit "EmailConfirmed", @

      callback null


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
