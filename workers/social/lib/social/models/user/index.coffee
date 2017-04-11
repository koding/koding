uuid             = require 'uuid'
async            = require 'async'
jraphical        = require 'jraphical'
Regions          = require 'koding-regions'
request          = require 'request'
KONFIG           = require 'koding-config-manager'
Flaggable        = require '../../traits/flaggable'
KodingError      = require '../../error'
emailsanitize    = require './emailsanitize'
{ extend, uniq } = require 'underscore'

{ protocol, hostname } = KONFIG

module.exports = class JUser extends jraphical.Module

  { Relationship }      = jraphical
  { secure, signature } = require 'bongo'

  JAccount             = require '../account'
  JSession             = require '../session'
  JInvitation          = require '../invitation'
  JName                = require '../name'
  JGroup               = require '../group'
  JLog                 = require '../log'
  ComputeProvider      = require '../computeproviders/computeprovider'
  Tracker              = require '../tracker'

  @bannedUserList = ['abrt', 'amykhailov', 'apache', 'about', 'visa', 'shared-',
                     'cthorn', 'daemon', 'dbus', 'dyasar', 'ec2-user', 'http',
                     'games', 'ggoksel', 'gopher', 'haldaemon', 'halt', 'mail',
                     'nfsnobody', 'nginx', 'nobody', 'node', 'operator', 'https',
                     'root', 'rpcuser', 'saslauth', 'shutdown', 'sinanlocal',
                     'sshd', 'sync', 'tcpdump', 'uucp', 'vcsa', 'zabbix',
                     'search', 'blog', 'activity', 'guest', 'credits', 'about',
                     'kodingen', 'alias', 'backup', 'bin', 'bind', 'daemon',
                     'Debian-exim', 'dhcp', 'drweb', 'games', 'gnats', 'klog',
                     'kluser', 'libuuid', 'list', 'mhandlers-user', 'more',
                     'mysql', 'nagios', 'news', 'nobody', 'popuser', 'postgres',
                     'proxy', 'psaadm', 'psaftp', 'qmaild', 'qmaill', 'qmailp',
                     'qmailq', 'qmailr', 'qmails', 'sshd', 'statd', 'sw-cp-server',
                     'sync', 'syslog', 'tomcat', 'tomcat55', 'uucp', 'what',
                     'www-data', 'fuck', 'porn', 'p0rn', 'porno', 'fucking',
                     'fucker', 'admin', 'postfix', 'puppet', 'main', 'invite',
                     'administrator', 'members', 'register', 'activate', 'shared',
                     'groups', 'blogs', 'forums', 'topics', 'develop', 'terminal',
                     'term', 'twitter', 'facebook', 'google', 'framework', 'kite',
                     'landing', 'hello', 'dev', 'sandbox', 'latest',
                     'all', 'channel', 'admins', 'group', 'team'
                   ]

  hashPassword = (value, salt) ->
    require('crypto').createHash('sha1').update(salt + value).digest('hex')

  createSalt = require 'hat'
  rack       = createSalt.rack 64

  @share()

  @trait __dirname, '../../traits/flaggable'

  @getFlagRole = -> 'owner'

  @set
    softDelete      : yes
    broadcastable   : no
    indexes         :
      username      : 'unique'
      email         : 'unique'
      sanitizedEmail: ['unique', 'sparse']

    sharedEvents    :
      # do not share any events
      static        : []
      instance      : []
    sharedMethods   :
      # do not share any instance methods
      # instances     :
      static        :
        login                   : (signature Object, Function)
        whoami                  : (signature Function)
        logout                  : (signature Function)
        convert                 : (signature Object, Function)
        fetchUser               : (signature Function)
        setSSHKeys              : (signature [Object], Function)
        getSSHKeys              : (signature Function)
        unregister              : (signature String, Function)
        verifyByPin             : (signature Object, Function)
        changeEmail             : (signature Object, Function)
        verifyPassword          : (signature Object, Function)
        emailAvailable          : (signature String, Function)
        changePassword          : (signature String, Function)
        usernameAvailable       : (signature String, Function)
        authenticateWithOauth   : (signature Object, Function)

    schema          :
      username      :
        type        : String
        validate    : JName.validateName
        set         : (value) -> value.toLowerCase()
      oldUsername   : String
      email         :
        type        : String
        validate    : JName.validateEmail
        set         : emailsanitize
      sanitizedEmail:
        type        : String
        validate    : JName.validateEmail
        set         : (value) ->
          return  unless typeof value is 'string'
          emailsanitize value, { excludeDots: yes, excludePlus: yes }
      password      : String
      salt          : String
      twofactorkey  : String
      blockedUntil  : Date
      blockedReason : String
      status        :
        type        : String
        enum        : [
          'invalid status type', [
            'unconfirmed', 'confirmed', 'blocked', 'deleted'
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

      # stores user preference for how often email should be sent.
      # see go/src/koding/db/models/user.go for more details.
      emailFrequency: Object

      sshKeys       :
        type        : Object
        default     : -> []

    relationships       :
      ownAccount        :
        targetType      : JAccount
        as              : 'owner'

  sessions  = {}
  users     = {}
  guests    = {}

  @unregister = secure (client, toBeDeletedUsername, callback) ->

    { delegate } = client.connection
    { nickname } = delegate.profile

    console.log "#{nickname} requested to delete: #{toBeDeletedUsername}"

    # deleter should be registered one
    if delegate.type is 'unregistered'
      return callback new KodingError 'You are not registered!'

    # only owner and the dummy admins can delete a user
    unless toBeDeletedUsername is nickname or
           delegate.can 'administer accounts'
      return callback new KodingError 'You must confirm this action!'

    username = @createGuestUsername()

    # Adding -rm suffix to separate them from real guests
    # -rm was intentional otherwise we are exceeding the max username length
    username = "#{username}-rm"

    # Why we do have such thing? ~ GG
    email = "#{username}@koding.com"

    @one { username: toBeDeletedUsername }, (err, user) ->
      return callback err  if err?

      unless user
        return callback new KodingError \
          "User not found #{toBeDeletedUsername}"

      userValues = {
        email               : email
        sanitizedEmail      : email
        # here we have a trick, emailBeforeDeletion is not in the schema but we
        # are setting it to the db. it is not in the schema because we dont want
        # it to be seen in the codebase and it wont be mapped to a JUser
        emailBeforeDeletion : user.email
        status              : 'deleted'
        username            : username
      }
      unsetValues = {
        sshKeys             : 1
        password            : 1
        salt                : 1
        twofactorkey        : 1
        onlineStatus        : 1
        registeredAt        : 1
        lastLoginDate       : 1
        passwordStatus      : 1
        emailFrequency      : 1
        oldUsername         : 1
        blockedUntil        : 1
        blockedReason       : 1
        registeredFrom      : 1
        inactive            : 1
      }
      modifier = { $set: userValues, $unset: unsetValues }
      # update the user with empty data

      user.update modifier, updateUnregisteredUserAccount({
        user, username, toBeDeletedUsername, client
      }, callback)

  logError = (message, rest...) ->
    console.error "[JUser::authenticateClient] #{message}", rest...

  @authenticateClient: (clientId, callback) ->

    # Let's try to lookup provided session first
    JSession.one { clientId }, (err, session) ->

      if err

        # This is a very rare state here
        logError 'error finding session', { err, clientId }
        callback new KodingError err

      else if not session

        # We couldn't find the session with given token
        # so we are creating a new one now.
        JSession.createSession (err, { session, account }) ->

          if err?
            logError 'failed to create session', { err }
            callback err

          else

            # Voila session created and sent back, scenario #1
            callback null, { session, account }

      else

        # So we have a session, let's check it out if its a valid one
        checkSessionValidity { session, clientId }, callback


  @getHash = getHash = (value) ->

    require('crypto').createHash('md5').update(value.toLowerCase()).digest('hex')


  # whoami
  #
  # Returns your JAccount instance based on the session data
  #
  # @return {DefaultResponse}
  #
  @whoami = ->
  @whoami = secure ({ connection:{ delegate } }, callback) -> callback null, delegate


  @getBlockedMessage = (toDate) ->

    return """
      This account has been put on suspension due to a violation of our acceptable use policy. The ban will be in effect until <b>#{toDate}.</b><br><br>

      If you have any questions, please email <a class="ban" href='mailto:ban@#{KONFIG.domains.mail}'>ban@#{KONFIG.domains.mail}</a> and allow 2-3 business days for a reply. Even though your account is banned, all your data is safe.<br><br>

      Please note, repeated violations of our acceptable use policy will result in the permanent deletion of your account.<br><br>

      Team Koding
    """


  checkBlockedStatus = (user, callback) ->

    return callback null  if user.status isnt 'blocked'

    if user.blockedUntil and user.blockedUntil > new Date
      toDate    = user.blockedUntil.toUTCString()
      message   = JUser.getBlockedMessage toDate
      callback new KodingError message

    else
      user.unblock callback


  @normalizeLoginId = (loginId, callback) ->

    if /@/.test loginId
      email = emailsanitize loginId
      JUser.someData { email }, { username: 1 }, (err, cursor) ->
        return callback err  if err

        cursor.nextObject (err, data) ->
          return callback err  if err?
          return callback new KodingError 'Unrecognized email'  unless data?

          callback null, data.username
    else
      process.nextTick -> callback null, loginId


  @login$ = secure (client, credentials, callback) ->

    { sessionToken : clientId, connection } = client
    @login clientId, credentials, (err, response) ->
      return callback err  if err
      connection.delegate = response.account
      callback null, response


  fetchSession = (options, callback) ->

    { clientId, username } = options

    # fetch session of the current requester
    JSession.fetchSession { clientId }, (err, { session: fetchedSession }) ->
      return callback err  if err

      session = fetchedSession
      unless session
        console.error "login: session not found #{username}"
        return callback new KodingError 'Couldn\'t restore your session!'

      callback null, session


  validateLoginCredentials = (options, callback) ->

    { username, password, tfcode } = options

    # check credential validity
    JUser.one { username }, (err, user) ->
      return logAndReturnLoginError username, err.message, callback if err

      # if user not found it means we dont know about given username
      unless user?
        return logAndReturnLoginError username, 'Unknown user name', callback

      # if password is autogenerated return error
      if user.getAt('passwordStatus') is 'needs reset'
        return logAndReturnLoginError username, \
          'You should reset your password in order to continue!', callback

      # check if provided password is correct
      unless user.checkPassword password
        return logAndReturnLoginError username, 'Access denied!', callback

      # check if user is using 2factor auth and provided key is ok
      if !!(user.getAt 'twofactorkey')

        unless tfcode
          return callback new KodingError \
            'TwoFactor auth Enabled', 'VERIFICATION_CODE_NEEDED'

        unless user.check2FactorAuth tfcode
          return logAndReturnLoginError username, 'Access denied!', callback

      # if everything is fine, just continue
      callback null, user


  fetchInvitationByCode = (invitationToken, callback) ->

    JInvitation = require '../invitation'
    JInvitation.byCode invitationToken, (err, invitation) ->
      return callback err  if err
      return callback new KodingError 'invitation is not valid'  unless invitation
      callback null, invitation


  fetchInvitationByData = (options, callback) ->

    { user, groupName } = options

    selector = { email: user.email, groupName }
    JInvitation = require '../invitation'
    JInvitation.one selector, {}, (err, invitation) ->
      callback err, invitation


  validateLogin = (options, callback) ->

    { loginId, clientId, password, tfcode } = options

    username = null

    async.series {

      username: (next) ->
        JUser.normalizeLoginId loginId, (err, username_) ->
          username = username_?.toLowerCase?() or ''
          next err, username

      # fetch session and check for brute force attack
      session: (next) ->
        fetchSession { clientId, username }, (err, session) ->
          return next err  if err

          bruteForceControlData =
            ip        : session.clientIP
            username  : username

          # todo add alert support(mail, log etc)
          JLog.checkLoginBruteForce bruteForceControlData, (res) ->
            unless res
              return next new KodingError \
                "Your login access is blocked for #{JLog.timeLimit()} minutes."

            next null, session

      user: (next) ->
        validateLoginCredentials { username, password, tfcode }, (err, user) ->
          next err, user

    }, callback


  @login = (clientId, credentials, callback) ->

    { username: loginId, password, groupIsBeingCreated
      groupName, tfcode, invitationToken } = credentials

    user        = null
    session     = null
    account     = null
    username    = null
    groupName  ?= 'koding'
    invitation  = null

    queue = [

      (next) ->
        args = { loginId, clientId, password, tfcode }
        validateLogin args, (err, data) ->
          return next err  if err
          { username, user, session } = data
          next()

      (next) ->
        # fetch account of the user, we will use it later
        JAccount.one { 'profile.nickname' : username }, (err, account_) ->
          return next new KodingError 'couldn\'t find account!'  if err
          account = account_
          next()

      (next) ->
        { isSoloAccessible } = require './validators'

        opts =
          groupName: groupName
          account: account
          env: KONFIG.environment

        return next() if isSoloAccessible opts

        next  new Error 'You can not login to koding team, please use your own team'

      (next) ->
        # if we dont have an invitation code, do not continue
        return next()  unless invitationToken

        # check if user can access to group
        #
        # there can be two cases here
        # # user is member, check validity
        # # user is not member, and trying to access with invitationToken
        # both should succeed
        fetchInvitationByCode invitationToken, (err, invitation_) ->
          return next err  if err
          invitation = invitation_
          next()

      (next) ->
        # check if user has pending invitation
        return next()  if invitationToken

        fetchInvitationByData { user, groupName }, (err, invitation_) ->
          return next err  if err
          invitation = invitation_
          next()

      (next) =>
        return next()  if groupIsBeingCreated

        @addToGroupByInvitation { groupName, account, user, invitation }, next

      (next) ->
        return next()  if groupIsBeingCreated
        # we are sure that user can access to the group, set group name into
        # cookie while logging in
        session.update { $set : { groupName } }, next

    ]

    async.series queue, (err) ->
      return callback err  if err

      # continue login
      afterLogin user, clientId, session, (err, response) ->
        return callback err  if err
        callback err, response


  @verifyPassword = secure (client, options, callback) ->

    { password, email }           = options
    { connection : { delegate } } = client

    email = emailsanitize email  if email

    # handles error and decide to invalidate pin or not
    # depending on email and user variables
    handleError = (err, user) ->
      if email and user
        # when email and user is set, we need to invalidate verification token
        params =
          email     : email
          action    : 'update-email'
          username  : user.username
        JVerificationToken = require '../verificationtoken'
        JVerificationToken.invalidatePin params, (err) ->
          return console.error 'Pin invalidation error occurred', err  if err
      callback err, no

    # fetch user for invalidating created token
    @fetchUser client, (err, user) ->
      return handleError err  if err

      if not password or password is ''
        return handleError new KodingError('Password cannot be empty!'), user

      confirmed = user.getAt('password') is hashPassword password, user.getAt('salt')
      return callback null, yes  if confirmed

      return handleError null, user


  verifyByPin: (options, callback) ->

    if (@getAt 'status') is 'confirmed'
      return callback null

    JVerificationToken = require '../verificationtoken'

    { pin, resendIfExists } = options

    email    = @getAt 'email'
    username = @getAt 'username'

    options  = {
      user   : this
      action : 'verify-account'
      resendIfExists, pin, username, email
    }

    unless pin?
      JVerificationToken.requestNewPin options, (err) -> callback err

    else
      JVerificationToken.confirmByPin options, (err, confirmed) =>

        if err
          callback err
        else if confirmed
          @confirmEmail callback
        else
          callback new KodingError 'PIN is not confirmed.'


  @verifyByPin = secure (client, options, callback) ->

    account = client.connection.delegate
    account.fetchUser (err, user) ->

      return callback new Error 'User not found'  unless user

      user.verifyByPin options, callback


  @addToGroupByInvitation = (options, callback) ->

    { groupName, account, user, invitation } = options

    # check for membership
    JGroup.one { slug: groupName }, (err, group) ->

      return callback new KodingError err                   if err
      return callback new KodingError 'group doesnt exist'  if not group

      group.isMember account, (err, isMember) ->
        return callback err   if err
        return callback null  if isMember # if user is already member, we can continue

        # addGroup will check all prerequistes about joining to a group
        JUser.addToGroup account, groupName, user.email, invitation, callback


  redeemInvitation = (options, callback) ->

    { account, invitation, slug, email } = options

    return invitation.accept account, callback  if invitation

    JInvitation.one { email, groupName : slug }, (err, invitation_) ->
      # if we got error or invitation doesnt exist, just return
      return callback null if err or not invitation_
      return invitation_.accept account, callback


  # check if user's email domain is in allowed domains
  checkWithDomain = (groupName, email, callback) ->
    JGroup.one { slug: groupName }, (err, group) ->
      return callback err  if err
      # yes weird, but we are creating user before creating group
      return callback null, { isEligible: yes } if not group

      unless group.isInAllowedDomain email
        domainErr = 'Your email domain is not in allowed domains for this group'
        return callback new KodingError domainErr  if group.allowedDomains?.length > 0
        return callback new KodingError 'You are not allowed to access this team'

      return callback null, { isEligible: yes }


  terminateSession = (reason, clientId, callback) ->

    JUser.logout clientId, (err) ->
      logError reason, clientId
      callback new KodingError reason


  checkSessionValidity = (options, callback) ->

    { session, clientId } = options
    { username } = session

    unless username?

      # A session without a username is nothing, let's kill it
      # and logout the user, this is also a rare condition
      terminateSession 'no username found', clientId, callback

      return

    # If we are dealing with a guest session we know that we need to
    # use fake guest user

    if session.isGuestSession()

      JUser.fetchGuestUser (err, response) ->

        if err
          return terminateSession 'error fetching guest account', clientId, callback

        { account } = response
        if not response?.account
          return terminateSession 'guest account not found', clientId, callback

        account.profile.nickname = username

        return callback null, { account, session }

      return

    JUser.one { username }, (err, user) ->

      if err

        terminateSession 'error finding user with username', clientId, callback

      else unless user

        terminateSession "no user found with #{username} and sessionId", clientId, callback

      else

        context = { group: session?.groupName ? 'koding' }

        user.fetchAccount context, (err, account) ->

          if err

            terminateSession 'error fetching account', clientId, callback

          else

            # At this point we will mark this session as accessed
            # we can write down an updater to update lastAccess ~ GG
            # see: https://github.com/koding/koding/pull/10957/files#r110447280
            # session.lastAccess = lastAccess = new Date
            # session.update { $set: { lastAccess } }, (err) ->
            #   return callback err  if err

            # A valid session, a valid user attached to
            # it voila, scenario #2
            callback null, { session, account }


  updateUnregisteredUserAccount = (options, callback) ->

    { username : usernameAfterDelete, toBeDeletedUsername, user, client } = options

    return (err, docs) ->
      return callback err  if err?

      accountValues = {
        type                      : 'deleted'
        'profile.nickname'        : usernameAfterDelete
      }

      unsetValues = {
        shareLocation               : 1
        skillTags                   : 1
        locationTags                : 1
        systemInfo                  : 1
        counts                      : 1
        environmentIsCreated        : 1
        'profile.about'             : 1
        'profile.hash'              : 1
        'profile.ircNickname'       : 1
        'profile.firstName'         : 1
        'profile.lastName'          : 1
        'profile.description'       : 1
        'profile.avatar'            : 1
        'profile.status'            : 1
        'profile.experience'        : 1
        'profile.experiencePoints'  : 1
        'profile.lastStatusUpdate'  : 1
        referrerUsername            : 1
        referralUsed                : 1
        preferredKDProxyDomain      : 1
        isExempt                    : 1
        globalFlags                 : 1
        'meta._events'              : 1
        'meta.delimiter'            : 1
        'meta.likes'                : 1
        'meta.listenerTree'         : 1
        'meta.tags'                 : 1
        'meta.views'                : 1
        'meta.votes'                : 1
        onlineStatus                : 1
        migration                   : 1
      }

      params = { 'profile.nickname' : toBeDeletedUsername }
      JAccount.one params, (err, account) ->
        return callback err  if err?

        unless account
          return callback new KodingError \
            "Account not found #{toBeDeletedUsername}"

        # update the account to be deleted with empty data
        account.update { $set: accountValues }, (err) ->
          return callback err  if err?
          JName.release toBeDeletedUsername, (err) ->
            return callback err  if err?
            JAccount.emit 'UsernameChanged', {
              oldUsername    : toBeDeletedUsername
              isRegistration : false
              username       : usernameAfterDelete
            }

            user.unlinkOAuths ->
              account.leaveFromAllGroups client, ->
                deletedClient = { connection: { delegate: account } }
                JUser.logout deletedClient, callback

  validateConvertInput = (userFormData, client) ->

    { username
      password
      passwordConfirm }         = userFormData
    { connection }              = client
    { delegate : account }      = connection

    # only unregistered accounts can be "converted"
    if account.type is 'registered'
      return new KodingError 'This account is already registered.'

    if /^guest-/.test username
      return new KodingError 'Reserved username!'

    if username is 'guestuser'
      return new KodingError 'Reserved username: \'guestuser\'!'

    if password isnt passwordConfirm
      return new KodingError 'Passwords must match!'

    unless typeof username is 'string'
      return new KodingError 'Username must be a string!'

    return null


  logAndReturnLoginError = (username, error, callback) ->

    JLog.log { type: 'login', username: username, success: no }, ->
      callback new KodingError error


  updateUserPasswordStatus = (user, callback) ->
    # let user log in for the first time, than set password status
    # as 'needs reset'
    if user.passwordStatus is 'needs set'
      user.update { $set : { passwordStatus : 'needs reset' } }, callback
    else
      callback null


  afterLogin = (user, clientId, session, callback) ->

    { username }      = user

    account           = null
    replacementToken  = null

    queue = [

      (next) ->
        # fetching account, will be used to check login constraints of user
        user.fetchOwnAccount (err, account_) ->
          return next err  if err
          account = account_
          next()

      (next) ->
        # checking login constraints
        checkBlockedStatus user, next

      (next) ->
        # updating user passwordStatus if necessary
        updateUserPasswordStatus user, (err) ->
          return next err  if err
          replacementToken = uuid.v4()
          next()

      (next) ->
        # updating session data after login
        sessionUpdateOptions =
          $set                :
            username          : username
            clientId          : replacementToken
            lastLoginDate     : lastLoginDate = new Date
          $unset              :
            guestId           : 1
            guestSessionBegan : 1

        guestUsername = session.username

        session.update sessionUpdateOptions, (err) ->
          return next err  if err

          Tracker.identify username, { lastLoginDate }
          Tracker.alias guestUsername, username

          next()

      (next) ->

        if session.foreignAuth

          JForeignAuth = require '../foreignauth'
          JForeignAuth.persistOauthInfo {
            sessionToken: replacementToken
            group: session.groupName
            username
          }, (err) ->

            return next err  if err

            # TRACKER ----------------------------------------------- >> --
            providers = {}
            Object.keys(session.foreignAuth).forEach (provider) ->
              providers[provider] = yes

            Tracker.identify user.username, { foreignAuth: providers }
            # TRACKER ----------------------------------------------- << --

            next null

        else
          next()

      (next) ->

        # updating user data after login
        userUpdateOptions =
          $set        : { lastLoginDate : new Date }
          $unset      :
            inactive  : 1

        user.update userUpdateOptions, (err) ->
          return next err  if err

          JLog.log { type: 'login', username , success: yes }

          next()

      (next) ->
        JSession.clearOauthInfo session, next

    ]

    async.series queue, (err) ->
      return callback err  if err
      callback null, { account, replacementToken, returnUrl: session.returnUrl }

      Tracker.track username, { subject : Tracker.types.LOGGED_IN }


  @logout = secure (client, callback) ->

    if 'string' is typeof client
      sessionToken = client
    else
      { sessionToken } = client
      delete client.connection.delegate
      delete client.sessionToken

    # if sessionToken doesnt exist, safe to return
    return callback null unless sessionToken

    JSession.remove { clientId: sessionToken }, callback


  @verifyEnrollmentEligibility = (options, callback) ->

    { email, invitationToken, groupName, skipAllowedDomainCheck } = options

    # return without checking domain if skipAllowedDomainCheck is true
    return callback null, { isEligible : yes }  if skipAllowedDomainCheck

    # check if email domain is in allowed domains
    return checkWithDomain groupName, email, callback  unless invitationToken

    JInvitation = require '../invitation'
    JInvitation.byCode invitationToken, (err, invitation) ->
      # check if invitation exists
      if err or not invitation?
        return callback new KodingError 'Invalid invitation code!'

      # check if invitation is valid
      if invitation.isValid() and  invitation.groupName is groupName
        return callback null, { isEligible: yes, invitation }

      # last resort, check if email domain is under allowed domains
      return checkWithDomain groupName, email, callback


  @addToGroup = (account, slug, email, invitation, options, callback) ->

    [options, callback] = [{}, options]  unless callback

    options.email           = email
    options.groupName       = slug
    options.invitationToken = invitation.code  if invitation?.code

    JUser.verifyEnrollmentEligibility options, (err, res) ->
      return callback err  if err
      return callback new KodingError 'malformed response' if not res
      return callback new KodingError 'can not join to group' if not res.isEligible

      # fetch group that we are gonna add account in
      JGroup.one { slug }, (err, group) ->
        return callback err   if err
        return callback null  if not group

        roles = ['member']
        if invitation?.role and slug isnt 'koding'
          roles.push invitation.role
        roles = uniq roles

        group.approveMember account, roles, (err) ->
          return callback err  if err

          if code = invitation?.code
            groupUrl   = "#{protocol}//#{slug}.#{hostname}"
            properties =
              groupName : slug
              link      : "#{groupUrl}/Invitation/#{encodeURIComponent code}"

            options    =
              subject   : Tracker.types.TEAMS_JOINED_TEAM

            Tracker.identifyAndTrack email, options, properties

          # do not forget to redeem invitation
          redeemInvitation {
            account, invitation, slug, email
          }, callback


  @addToGroups = (account, slugs, email, invitation, options, callback) ->

    [options, callback] = [{}, options]  unless callback

    slugs.push invitation.groupName if invitation?.groupName
    slugs = uniq slugs # clean up slugs
    queue = slugs.map (slug) => (fin) =>
      @addToGroup account, slug, email, invitation, options, fin

    async.parallel queue, callback


  @createGuestUsername = -> "guest-#{rack()}"


  @fetchGuestUser = (callback) ->

    username      = @createGuestUsername()

    account = new JAccount()
    account.profile = { nickname: username }
    account.type = 'unregistered'

    callback null, { account, replacementToken: uuid.v4() }


  @createUser = (userInfo, callback) ->

    { username, email, password, passwordStatus,
      firstName, lastName, silence, emailFrequency } = userInfo

    if typeof username isnt 'string'
      return callback new KodingError 'Username must be a string!'

    # lower casing username is necessary to prevent conflicts with other JModels
    username       = username.toLowerCase()
    email          = emailsanitize email
    sanitizedEmail = emailsanitize email, { excludeDots: yes, excludePlus: yes }

    emailFrequencyDefaults = {
      global         : on
      daily          : off
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

    JName.claim username, [slug], 'JUser', (err, nameDoc) ->

      return callback err  if err

      salt = createSalt()
      user = new JUser {
        username
        email
        sanitizedEmail
        salt
        password         : hashPassword password, salt
        passwordStatus   : passwordStatus or 'valid'
        emailFrequency   : emailFrequency
      }

      user.save (err) ->

        if err
          nameDoc.remove?()
          return if err.code is 11000
          then callback new KodingError "Sorry, \"#{email}\" is already in use!"
          else callback err

        account      = new JAccount
          profile    : {
            nickname : username
            hash     : getHash email
            firstName
            lastName
          }

        account.save (err) ->

          if err
            user.remove?()
            nameDoc.remove?()
            callback err
          else user.addOwnAccount account, (err) ->
            if err then callback err
            else callback null, user, account


  @authenticateWithOauth = secure (client, resp, callback) ->

    unless client
      return callback new KodingError 'Couldn\'t restore your session!'

    { isUserLoggedIn, provider } = resp
    { sessionToken } = client

    JSession.one { clientId: sessionToken }, (err, session) =>
      return callback new KodingError err  if err

      unless session
        { connection: { delegate: { profile: { nickname } } } } = client
        console.error 'authenticateWithOauth: session not found', nickname

        return callback new KodingError 'Couldn\'t restore your session!'

      kallback = (err, resp = {}) ->
        { account, replacementToken, returnUrl } = resp
        callback err, {
          isNewUser : false
          userInfo  : null
          account
          replacementToken
          returnUrl
        }

      { nickname: requester } = client.connection.delegate.profile

      options = { session, provider }

      JForeignAuth = require '../foreignauth'
      JForeignAuth.fetchFromSession options, (err, data) =>

        return callback new KodingError err.message  if err

        { user, foreignData } = data ? {}

        if isUserLoggedIn

          if foreignData and foreignData.username isnt requester
            JSession.clearOauthInfo session, ->
              callback new KodingError '''
                Account is already linked with another user.
              '''
          else
            @fetchUser client, (err, user) ->
              return callback new KodingError err.message  if err
              JForeignAuth.persistOauthInfo {
                username: user.username
                group: session.groupName
                sessionToken
              }, kallback

        else
          if user
            afterLogin user, sessionToken, session, kallback
          else
            callback new KodingError '''
              Login with username and password to enable this integration
            '''


  @validateAll = (userFormData, callback) ->

    Validator  = require './validators'
    validator  = new Validator

    isError    = no
    errors     = {}
    queue      = []

    (key for key of validator).forEach (field) =>

      queue.push (fin) => validator[field].call this, userFormData, (err) ->

        if err?
          errors[field] = err
          isError = yes

        fin()

    async.parallel queue, ->

      callback if isError
        { message: 'Errors were encountered during validation', errors }
      else null


  @changeEmailByUsername = (options, callback) ->

    { account, oldUsername, email } = options
    # prevent from leading and trailing spaces
    email = emailsanitize email
    @update { username: oldUsername }, { $set: { email } }, (err, res) ->
      return callback err  if err
      account.profile.hash = getHash email
      account.save (err) -> console.error if err
      callback null


  @changeUsernameByAccount = (options, callback) ->

    { account, username, clientId, isRegistration, groupName } = options
    account.changeUsername { username, isRegistration }, (err) ->
      return callback err   if err?
      return callback null  unless clientId?
      newToken = uuid.v4()
      JSession.one { clientId }, (err, session) ->
        if err?
          return callback new KodingError 'Could not update your session'

        if session?
          sessionUpdateOptions =
            $set   : { clientId : newToken, username, groupName }
            $unset : { guestSessionBegan : 1 }

          session.update sessionUpdateOptions, (err) ->
            return callback err  if err?
            callback null, newToken

        else
          callback new KodingError 'Session not found!'


  @removeFromGuestsGroup = (account, callback) ->

    JGroup.one { slug: 'guests' }, (err, guestsGroup) ->
      return callback err  if err?
      return callback new KodingError 'Guests group not found!'  unless guestsGroup?
      guestsGroup.removeMember account, callback


  createGroupStack = (account, groupName, callback) ->

    _client =
      connection :
        delegate : account
      context    :
        group    : groupName

    ComputeProvider.createGroupStack _client, (err) ->
      if err?
        console.warn "Failed to create group stack for #{account.profile.nickname}:", err

      # We are not returning error here on purpose, even stack template
      # not created for a user we don't want to break registration process
      # at all ~ GG
      callback()


  verifyUser = (options, callback) ->

    { slug
      email
      recaptcha
      disableCaptcha
      userFormData } = options

    queue = [

      (next) ->
        # verifying recaptcha if enabled
        return next()  if disableCaptcha or not KONFIG.recaptcha.enabled

        JUser.verifyRecaptcha recaptcha, { slug }, next

      (next) ->
        JUser.validateAll userFormData, next

      (next) ->
        JUser.emailAvailable email, (err, res) ->
          if err
            return next new KodingError 'Something went wrong'

          if res is no
            return next new KodingError 'Email is already in use!'

          next()

    ]

    async.series queue, callback


  createUser = (options, callback) ->

    { userInfo } = options

    # creating a new user
    JUser.createUser userInfo, (err, user, account) ->
      return callback err  if err

      unless user? and account?
        return callback new KodingError 'Failed to create user!'

      callback null, { user, account }


  updateUserInfo = (options, callback) ->

    { user, ip, country, region, username,
      client, account, clientId, password } = options

    newToken = null

    queue = [

      (next) ->
        # updating user's location related info
        return next()  unless ip? and country? and region?

        locationModifier =
          $set                       :
            'registeredFrom.ip'      : ip
            'registeredFrom.region'  : region
            'registeredFrom.country' : country

        user.update locationModifier, ->
          next()

      (next) ->
        JForeignAuth = require '../foreignauth'
        JForeignAuth.persistOauthInfo {
          sessionToken: client.sessionToken
          group: client.context.group
          username
        }, next

      (next) ->
        return next()  unless username?

        _options =
          account        : account
          username       : username
          clientId       : clientId
          groupName      : client.context.group
          isRegistration : yes

        JUser.changeUsernameByAccount _options, (err, newToken_) ->
          return next err  if err
          newToken = newToken_
          next()

      (next) ->
        user.setPassword password, next

    ]

    async.series queue, (err) ->
      return callback err  if err
      callback null, newToken


  updateAccountInfo = (options, callback) ->

    { account, referrer, username } = options

    queue = [

      (next) ->
        account.update { $set: { type: 'registered' } }, next

      (next) ->
        account.createSocialApiId next

      (next) ->
        # setting referrer
        return next()  unless referrer

        if username is referrer
          console.error "User (#{username}) tried to refer themself."
          return next()

        JUser.count { username: referrer }, (err, count) ->
          if err? or count < 1
            console.error 'Provided referrer not valid:', err
            return next()

          account.update { $set: { referrerUsername: referrer } }, (err) ->

            if err?
            then console.error err
            else console.log "#{referrer} referred #{username}"

            next()

    ]

    async.series queue, callback


  createDefaultStackForKodingGroup = (options, callback) ->

    { account } = options

    # create default stack for koding group, when a user joins this is only
    # required for koding group, not neeed for other teams
    _client =
      connection :
        delegate : account
      context    :
        group    : 'koding'

    ComputeProvider.createGroupStack _client, (err) ->
      if err?
        console.warn "Failed to create group stack
                      for #{account.profile.nickname}:#{err}"

      # We are not returning error here on purpose, even stack template
      # not created for a user we don't want to break registration process
      # at all ~ GG
      callback null


  confirmAccountIfNeeded = (options, callback) ->

    { user, email, username, group } = options

    if KONFIG.autoConfirmAccounts or group isnt 'koding'
      user.confirmEmail (err) ->
        console.warn err  if err?
        return callback err

    else
      _options =
        email    : email
        action   : 'verify-account'
        username : username

      JVerificationToken = require '../verificationtoken'
      JVerificationToken.createNewPin _options, (err, confirmation) ->
        console.warn 'Failed to send verification token:', err  if err
        callback err, confirmation?.pin


  validateConvert = (options, callback) ->

    { client, userFormData, skipAllowedDomainCheck } = options
    { slug, email, invitationToken, recaptcha, disableCaptcha } = userFormData

    invitation = null

    queue = [

      (next) ->
        params = { slug, email, recaptcha, disableCaptcha, userFormData }
        verifyUser params, next

      (next) ->
        params = {
          groupName : client.context.group
          invitationToken, skipAllowedDomainCheck, email
        }

        JUser.verifyEnrollmentEligibility params, (err, res) ->
          return next err  if err

          { isEligible, invitation } = res

          if not isEligible
            return next new Error "you can not register to #{client.context.group}"
          next()

    ]

    async.series queue, (err) ->
      return callback err  if err
      callback null, { invitation }


  processConvert = (options, callback) ->

    { ip, country, region, client, invitation
      userFormData, skipAllowedDomainCheck } = options
    { sessionToken : clientId } = client
    { referrer, email, username, password,
    emailFrequency, firstName, lastName } = userFormData

    user     = null
    error    = null
    account  = null
    newToken = null

    queue = [

      (next) ->
        userInfo = {
          email, username, password, lastName, firstName, emailFrequency
        }
        createUser { userInfo }, (err, data) ->
          return next err  if err
          { user, account } = data
          next()

      (next) ->
        params = {
          user, ip, country, region, username
          password, clientId, account, client
        }
        updateUserInfo params, (err, newToken_) ->
          return next err  if err
          newToken = newToken_
          next()

      (next) ->
        updateAccountInfo { account, referrer, username }, next

      (next) ->
        groupNames = [client.context.group, 'koding']
        options    = { skipAllowedDomainCheck }
        JUser.addToGroups account, groupNames, user.email, invitation, options, (err) ->
          error = err
          next()

      (next) ->
        createDefaultStackForKodingGroup { account }, next

    ]

    async.series queue, (err) ->
      return callback err  if err

      # passing "error" variable to be used as an argument in the callback func.
      # that is being called after registration process is completed.
      callback null, { error, newToken, user, account }


  @convert = secure (client, userFormData, options, callback) ->

    [options, callback] = [{}, options]  unless callback

    { slug, email, agree, username, lastName, referrer,
      password, firstName, recaptcha, emailFrequency,
      invitationToken, passwordConfirm, disableCaptcha } = userFormData

    { skipAllowedDomainCheck } = options
    { clientIP, connection }   = client
    { delegate : account }     = connection
    { nickname : oldUsername } = account.profile

    # if firstname is not received use username as firstname
    userFormData.firstName = username  unless firstName
    userFormData.lastName  = ''        unless lastName

    if error = validateConvertInput userFormData, client
      return callback error

    # lower casing username is necessary to prevent conflicts with other JModels
    username = userFormData.username = username.toLowerCase()
    email    = userFormData.email    = emailsanitize email

    if clientIP
      { ip, country, region } = Regions.findLocation clientIP

    pin              = null
    user             = null
    error            = null
    newToken         = null
    invitation       = null
    subscription     = null

    queue = [

      (next) ->
        options = { client, userFormData, skipAllowedDomainCheck }
        validateConvert options, (err, data) ->
          return next err  if err
          { invitation } = data
          next()

      (next) ->
        params = {
          ip, country, region, client, invitation
          userFormData, skipAllowedDomainCheck
        }
        processConvert params, (err, data) ->
          return next err  if err
          { error, newToken, user, account } = data
          next()

      (next) ->
        date = new Date 0
        subscription =
          accountId          : account.getId()
          planTitle          : 'free'
          planInterval       : 'month'
          state              : 'active'
          provider           : 'koding'
          expiredAt          : date
          canceledAt         : date
          currentPeriodStart : date
          currentPeriodEnd   : date

        args = { user, account, subscription, pin, oldUsername }
        identifyUserOnRegister disableCaptcha, args

        JUser.emit 'UserRegistered', { user, account }

        next()

      (next) ->
        # Auto confirm accounts for development environment or Teams ~ GG
        args = { group : client.context.group, user, email, username }
        confirmAccountIfNeeded args, (err, pin_) ->
          pin = pin_
          next err

    ]

    async.series queue, (err) ->
      return callback err  if err

      # don't block register
      callback error, { account, newToken, user }

      group = client.context.group
      args  = { user, group, pin, firstName, lastName }
      trackUserOnRegister disableCaptcha, args

  identifyUserOnRegister = (disableCaptcha, args) ->

    return  if disableCaptcha

    { user, account, subscription, pin, oldUsername } = args
    { status, lastLoginDate, username, email } = user
    { createdAt, profile } = account.meta
    { firstName, lastName } = account.profile

    jwtToken = JUser.createJWT { username }

    sshKeysCount = user.sshKeys.length

    emailFrequency =
      global       : user.emailFrequency.global
      marketing    : user.emailFrequency.marketing

    traits = {
      email
      createdAt
      lastLoginDate
      status

      firstName
      lastName

      subscription
      sshKeysCount
      emailFrequency

      pin
      jwtToken
    }

    Tracker.identify username, traits
    Tracker.alias oldUsername, username


  trackUserOnRegister = (disableCaptcha, args) ->

    return  if disableCaptcha

    subject = Tracker.types.START_REGISTER
    { user, group, pin, firstName, lastName } = args
    { username, email } = user

    opts = { pin, group, user : { user_id : username, email, firstName, lastName } }
    Tracker.track username, { to : email, subject }, opts


  @createJWT: (data, options = {}) ->
    { secret, expiresIn } = KONFIG.jwt

    jwt = require 'jsonwebtoken'
    options.expiresIn ?= expiresIn

    return jwt.sign data, secret, options

  @grantInitialInvitations = (username) ->
    JInvitation.grant { 'profile.nickname': username }, 3, (err) ->
      console.log 'An error granting invitations', err if err


  @fetchUser = secure (client, callback) ->

    JSession.one { clientId: client.sessionToken }, (err, session) ->
      return callback err  if err

      noUserError = -> new KodingError \
        'No user found! Not logged in or session expired'

      if not session or not session.username
        return callback noUserError()

      JUser.one { username: session.username }, (err, user) ->

        if err or not user
          console.log '[JUser::fetchUser]', err  if err?
          callback noUserError()
        else
          callback null, user


  @changePassword = secure (client, password, callback) ->

    @fetchUser client, (err, user) ->

      if err or not user
        return callback new KodingError \
          'Something went wrong please try again!'

      if user.getAt('password') is hashPassword password, user.getAt('salt')
        return callback new KodingError 'PasswordIsSame'

      user.changePassword password, (err) ->
        return callback err  if err

        account  = client.connection.delegate
        clientId = client.sessionToken

        account.sendNotification 'SessionHasEnded', { clientId }

        selector = { clientId: { $ne: client.sessionToken } }

        user.killSessions selector, callback


  sendChangedEmail = (username, firstName, to, type) ->

    subject = if type is 'email' then Tracker.types.CHANGED_EMAIL
    else Tracker.types.CHANGED_PASSWORD

    Tracker.track username, { to, subject }, { firstName }


  @changeEmail = secure (client, options, callback) ->

    { email } = options

    email = options.email = emailsanitize email

    account = client.connection.delegate
    account.fetchUser (err, user) =>
      return callback new KodingError 'Something went wrong please try again!' if err
      return callback new KodingError 'EmailIsSameError' if email is user.email

      @emailAvailable email, (err, res) ->
        return callback new KodingError 'Something went wrong please try again!' if err

        if res is no
          callback new KodingError 'Email is already in use!'
        else
          user.changeEmail account, options, callback


  @emailAvailable = (email, callback) ->

    unless typeof email is 'string'
      return callback new KodingError 'Not a valid email!'

    sanitizedEmail = emailsanitize email, { excludeDots: yes, excludePlus: yes }

    @count { sanitizedEmail }, (err, count) ->
      callback err, count is 0


  @getValidUsernameLengthRange = -> { minLength : 4, maxLength : 25 }


  @usernameAvailable = (username, callback) ->

    JName     = require '../name'

    username += ''
    res       =
      kodingUser : no
      forbidden  : yes

    JName.count { name: username }, (err, count) =>
      { minLength, maxLength } = JUser.getValidUsernameLengthRange()

      if err or username.length < minLength or username.length > maxLength
        callback err, res
      else
        res.kodingUser = count is 1
        res.forbidden  = username in @bannedUserList
        callback null, res


  fetchAccount: (context, rest...) -> @fetchOwnAccount rest...


  setPassword: (password, callback) ->

    salt = createSalt()
    @update {
      $set             :
        salt           : salt
        password       : hashPassword password, salt
        passwordStatus : 'valid'
    }, callback


  changePassword: (newPassword, callback) ->

    @setPassword newPassword, (err) =>
      return callback err  if err

      @fetchAccount 'koding', (err, account) =>
        return callback err  if err
        return callback new KodingError 'Account not found' unless account

        { firstName } = account.profile
        sendChangedEmail @getAt('username'), firstName, @getAt('email'), 'password'

        callback null


  changeEmail: (account, options, callback) ->

    JVerificationToken = require '../verificationtoken'

    { email, pin } = options

    email = options.email = emailsanitize email
    sanitizedEmail = emailsanitize email, { excludeDots: yes, excludePlus: yes }

    if account.type is 'unregistered'
      @update { $set: { email , sanitizedEmail } }, (err) ->
        return callback err  if err

        callback null
      return

    action = 'update-email'

    if not pin

      options = {
        email, action, user: this, resendIfExists: yes
      }

      JVerificationToken.requestNewPin options, callback

    else
      options = {
        email, action, pin, username: @getAt 'username'
      }

      JVerificationToken.confirmByPin options, (err, confirmed) =>

        return callback err  if err

        unless confirmed
          return callback new KodingError 'PIN is not confirmed.'

        oldEmail = @getAt 'email'

        @update { $set: { email, sanitizedEmail } }, (err, res) =>
          return callback err  if err

          account.profile.hash = getHash email
          account.save (err) =>
            return callback err  if err

            { firstName } = account.profile

            # send EmailChanged event
            @constructor.emit 'EmailChanged', {
              username: @getAt('username')
              oldEmail: oldEmail
              newEmail: email
            }

            sendChangedEmail @getAt('username'), firstName, oldEmail, 'email'

            callback null

            Tracker.identify @username, { email }

  confirmEmail: (callback) ->

    status   = @getAt 'status'
    username = @getAt 'username'

    # for some reason status is sometimes 'undefined', so check for that
    if status? and status isnt 'unconfirmed'
      return callback null

    modifier = { status: 'confirmed' }

    @update { $set: modifier }, (err, res) =>
      return callback err if err
      JUser.emit 'EmailConfirmed', this

      callback null

      Tracker.identify username, modifier

      Tracker.track username, { subject: Tracker.types.FINISH_REGISTER }


  block: (blockedUntil, callback) ->

    unless blockedUntil then return callback new KodingError 'Blocking date is not defined'

    status = 'blocked'

    @update { $set: { status, blockedUntil } }, (err) =>

      return callback err if err

      JUser.emit 'UserBlocked', this

      console.log 'JUser#block JSession#remove', { @username, blockedUntil }

      # clear all of the cookies of the blocked user
      JSession.remove { username: @username }, callback

      Tracker.identify @username, { status }


  unblock: (callback) ->

    status = 'confirmed'

    op =
      $set   : { status }
      $unset : { blockedUntil: yes }

    @update op, (err) =>

      return callback err  if err

      JUser.emit 'UserUnblocked', this
      callback()

      Tracker.identify @username, { status }


  unlinkOAuths: (callback) ->

    @update { $unset: { foreignAuth:1 } }, (err) ->
      return callback err


  @setSSHKeys: secure (client, sshKeys, callback) ->

    @fetchUser client, (err, user) ->
      user.sshKeys = sshKeys
      user.save callback

      Tracker.identify user.username, { sshKeysCount: sshKeys.length }


  @getSSHKeys: secure (client, callback) ->

    @fetchUser client, (err, user) ->
      return callback user?.sshKeys or []


  ###*
   * Compare provided password with JUser.password
   *
   * @param {string} password
  ###
  checkPassword: (password) ->

    # hash of given password and given user's salt should match with user's password
    return @getAt('password') is hashPassword password, @getAt('salt')


  ###*
   * Compare provided verification token with time
   * based generated 2Factor code. If 2Factor not enabled returns true
   *
   * @param {string} verificationCode
  ###
  check2FactorAuth: (verificationCode) ->

    key          = @getAt 'twofactorkey'

    speakeasy    = require 'speakeasy'
    generatedKey = speakeasy.totp { key, encoding: 'base32' }

    return generatedKey is verificationCode


  ###*
   * Verify if `response` from client is valid by asking recaptcha servers.
   *
   * @param {string}   response
   * @param {function} callback
  ###
  @verifyRecaptcha = (response, params, callback) ->

    { url, secret } = KONFIG.recaptcha
    { slug }        = params

    # TODO: temporarily disable recaptcha for groups
    if slug? and slug isnt 'koding'
      return callback null

    request.post url, { form: { response, secret } }, (err, res, raw) ->
      if err
        console.log "Recaptcha: err validation captcha: #{err}"

      if not err and res.statusCode is 200
        try
          if JSON.parse(raw)['success']
            return callback null
        catch e
          console.log "Recaptcha: parsing response failed. #{raw}"

      return callback new KodingError 'Captcha not valid. Please try again.'


  ###*
   * Remove session documents matching selector object.
   *
   * @param {Object} [selector={}] - JSession query selector.
   * @param {Function} - Callback.
  ###
  killSessions: (selector = {}, callback) ->

    selector.username = @username
    JSession.remove selector, callback
