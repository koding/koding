_           = require 'underscore'
jraphical   = require 'jraphical'
async       = require 'async'
KodingError = require '../error'
ApiError    = require './socialapi/error'
Tracker     = require './tracker'
KONFIG      = require 'koding-config-manager'
backoff     = require 'backoff'
{ dummyAdmins } = KONFIG
{ checkUserPassword } = require './utils'


module.exports = class JAccount extends jraphical.Module

  @trait __dirname, '../traits/filterable'
  @trait __dirname, '../traits/notifying'
  @trait __dirname, '../traits/notifiable'
  @trait __dirname, '../traits/flaggable'

  JName               = require './name'
  JCombinedAppStorage = require './combinedappstorage'

  @getFlagRole            = 'content'
  @lastUserCountFetchTime = 0

  { ObjectId, secure, signature } = require 'bongo'
  { Relationship } = jraphical
  { permit } = require './group/permissionset'
  Validators = require './group/validators'
  Protected  = require '../traits/protected'
  { extend } = require 'underscore'
  async      = require 'async'

  validateFullName = (value) -> not /<|>/.test value

  @share()

  @set
    softDelete          : yes
    emitFollowingActivities : yes # create buckets for follower / followees
    indexes:
      'profile.nickname' : 'unique'
      isExempt           : 'ascending'
      type               : 'ascending'
    sharedEvents    :
      static        : []
      instance      : []
    sharedMethods :
      static:
        one: [
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        some:
          (signature Object, Object, Function)
        someWithRelationship:
          (signature Object, Object, Function)
        count: [
          (signature Function)
          (signature Object, Function)
        ]
        byRelevance:
          (signature String, Object, Function)
        verifyEmailByUsername:
          (signature String, Function)
        fetchBlockedUsers:
          (signature Object, Function)
        fetchEmailsByUsername:
          (signature Object, Function)

      instance:
        modify:
          (signature Object, Function)
        fetchAppStorage:
          (signature Object, Function)
        setEmailPreferences:
          (signature Object, Function)
        fetchRole:
          (signature Function)
        isFollowing:
          (signature String, String, Function)
        updateFlags:
          (signature [String], Function)
        fetchGroups: [
          (signature Function)
          (signature Object, Function)
        ]
        cancelRequest:
          (signature String, Function)
        acceptInvitation:
          (signature String, Function)
        ignoreInvitation:
          (signature String, Function)
        fetchMyPermissions:
          (signature Function)
        fetchMyPermissionsAndRoles:
          (signature Function)
        fetchMySessions:
          (signature Object, Function)
        blockUser: [
          (signature String, Number, Function)
          (signature ObjectId, Number, Function)
        ]
        unblockUser: [
          (signature String, Function)
          (signature ObjectId, Function)
        ]
        unlinkOauth:
          (signature String, Function)
        markUserAsExempt:
          (signature Boolean, Function)
        checkGroupMembership:
          (signature String, Function)
        isEmailVerified:
          (signature Function)
        fetchEmail:
          (signature Function)
        fetchPaymentMethods:
          (signature Function)
        fetchEmailAndStatus:
          (signature Function)
        fetchEmailFrequency:
          (signature Function)
        fetchOAuthInfo:
          (signature Function)
        fetchFromUser: [
          (signature String, Function)
          (signature [String], Function)
        ]
        fetchKites :
          (signature Object, Function)
        fetchRelativeGroups: [
          (signature Function)
          (signature Object, Function)
        ]
        expireSubscription:
          (signature Function)
        fetchOtaToken:
          (signature Function)
        generate2FactorAuthKey:
          (signature Function)
        setup2FactorAuth:
          (signature Object, Function)
        pushNotification:
          (signature Object, Function)
        destroy:
          (signature String, Function)


    schema                  :
      socialApiId           : String
      environmentIsCreated  : Boolean
      type                  :
        type                : String
        enum                : ['invalid account type', [
                                'registered'
                                'unregistered'
                                'deleted'
                              ]]
        default             : 'unregistered'
      profile               :
        nickname            :
          type              : String
          validate          : require('./name').validateName
          set               : (value) -> value.toLowerCase()
        hash                : String
        firstName           :
          type              : String
          required          : yes
          default           : 'a koding'
          validate          : validateFullName
        lastName            :
          type              : String
          default           : 'user'
          validate          : validateFullName
        avatar              : String
      referrerUsername      : String
      referralUsed          : Boolean
      isExempt              : # is a troll ?
        type                : Boolean
        default             : false
      globalFlags           : [String]
      meta                  : require 'bongo/bundles/meta'

    broadcastableRelationships : [ 'follower' ]


    relationships           : ->

      # bongo doesn't wait models to be loaded and this causes errors
      # in node.js tests so synchronously requiring them
      JCredential      = require './computeproviders/credential'
      JStackTemplate   = require './computeproviders/stacktemplate'

      return {
        domain        :
          as          : 'owner'
          targetType  : 'JProposedDomain'

        invitation    :
          as          : 'owner'
          targetType  : 'JInvitation'

        credential    :
          as          : ['owner', 'user']
          targetType  : JCredential

        stackTemplate :
          as          : 'user'
          targetType  : JStackTemplate
      }


  constructor: ->
    super

  canEditPost: permit 'edit posts'

  canDeletePost: permit 'delete posts'


  leaveFromAllGroups: secure (client, callback) ->
    { delegate } = client.connection

    roles = [ 'member', 'moderator', 'admin' ]

    @fetchAllParticipatedGroups { roles }, (err, groups) ->
      return callback err   if err
      return callback null  if not groups

      queue = groups.map (group) -> (fin) ->
        if group.slug in ['koding', 'guests'] # just skip koding & guests
          fin()
        else
          group.leave client, fin

      async.parallel queue, callback


  fetchAllParticipatedGroups: (options, callback) ->

    [ options, callback ] = [ callback, options ]  unless callback
    options  ?= {}

    { roles } = options

    unless Array.isArray roles
      roles = [ 'member', 'moderator', 'admin', 'owner' ]

    selector = {
      sourceName: 'JGroup'
      targetName: 'JAccount'
      targetId: @getId()
      as: { $in: roles }
    }

    Relationship.someData selector, { sourceId: 1, as: 1 }, (err, cursor) ->
      return callback err  if err
      return callback null, []  if not cursor

      cursor.toArray (err, arr) ->

        return callback err       if err
        return callback null, []  if not arr

        { uniq, map } = require 'underscore'

        # just get the unique group ids from relationship response
        groupIds = uniq map(arr, (rel) -> rel.sourceId)

        JGroup = require './group'
        JGroup.some { _id : { $in : groupIds } }, {}, (err, groups) ->
          return callback err  if err

          groups = groups.map (group) ->
            for rel in arr when group._id.equals rel.sourceId
              group.roles ?= []
              group.roles.push rel.as
            group

          callback null, groups


  fetchInvitedGroups: (callback) ->

    queue = [
      (next) =>
        @fetchEmail next
      (email, next) ->
        JInvitation = require './invitation'
        JInvitation.some { email, status : 'pending' }, { limit : 10 }, next
      (invitations, next) ->
        { uniq, map } = _
        slugs  = uniq map invitations, (invitation) -> invitation.groupName
        JGroup = require './group'
        JGroup.some { slug : { $in : slugs } }, {}, (err, groups) ->
          return next err  if err
          for group in groups
            groupInvitations = invitations.filter (invitation) ->
              invitation.groupName is group.slug
            group.invitationCode = groupInvitations.first?.code
          next null, groups
    ]

    async.waterfall queue, callback


  fetchRelativeGroups$: secure (client, options = {}, callback) ->

    delegate = client?.connection?.delegate
    currentGroup = client?.context?.group

    return callback new Error 'malformed request' unless delegate or currentGroup

    [ callback, options ] = [ options, callback ]  unless callback
    options ?= {}

    delegate.fetchRelativeGroups { roles: options.roles }, (err, groups) ->

      return callback err  if err

      rejectedSlugs = [ 'koding', currentGroup ]

      groups = _.reject groups, (group) -> group.slug in rejectedSlugs
      groups = _.sortBy groups, 'slug'

      callback null, groups


  fetchRelativeGroups: (options, callback) ->

    [ callback, options ] = [ options, callback ]  unless callback
    options ?= {}

    queue =
      participated: (next) =>
        @fetchAllParticipatedGroups options, (err, groups) =>
          return next err  if err
          JUser = require './user'
          username = @getAt 'profile.nickname'
          for group in groups
            group.jwtToken = JUser.createJWT { username, groupName : group.slug }
          next null, groups
      invited: (next) =>
        @fetchInvitedGroups next

    async.parallel queue, (err, results) ->
      return callback err  if err
      { participated, invited } = results
      groups = participated.concat invited
      callback null, groups


  createSocialApiId: (callback) ->

    if @type is 'unregistered'
      return callback null, -1

    return callback null, @socialApiId  if @socialApiId? and @socialApiId > 0
    { createAccount } = require './socialapi/requests'
    createAccount { id: @getId(), nickname: @profile.nickname }, (err, account) =>
      return callback new ApiError err  if err
      return callback new KodingError 'Account is not set, malformed response from social api'  unless account?.id
      @update { $set: { socialApiId: account.id, isExempt: account.isTroll } }, (err) ->
        # check for error
        if err
          console.error 'Error while creating account on social api', err
          return callback new KodingError 'Couldnt create/register Account'
        # check account
        # return account id from social api
        return callback null, account.id

  checkGroupMembership: secure (client, groupName, callback) ->
    unless client?.connection?.delegate
      return callback new KodingError 'invalid request'
    JAccount.checkGroupMembership client.connection.delegate, groupName, callback

  @checkGroupMembership: (account, groupName, callback) ->
    JGroup = require './group'
    JGroup.one { slug : groupName }, (err, group) ->
      return callback new KodingError 'An error occurred!' if err
      return callback new KodingError 'Group not found'  unless group

      Relationship.one {
        as          : 'member'
        targetId    : account.getId()
        sourceId    : group.getId()
      }, (err, relation) ->
        return callback new KodingError 'An error occurred!' if err
        return callback null, relation?

  changeUsername: (options, callback = (->)) ->
    { username, isRegistration } = options
    oldUsername = @profile.nickname

    if username is oldUsername

      if isRegistration

        # To keep safe all other listeners of 'UsernameChanged' event
        # we are checking for the `isRegistration` flag before returning
        # error here. Instead in here we are faking like we did the
        # username change sucessfully. ~ GG

        @constructor.emit 'UsernameChanged', {
          oldUsername, username, isRegistration
        }
        return callback null

      else
        return callback new KodingError 'Username was not changed!'

    # Validate username
    unless @constructor.validateAt 'profile.nickname', username
      return callback new KodingError 'Invalid username!'

    # Custom error helper, we are using it to free up new JName
    # for given username, if any error happens after JName creation.
    hasError = (err) ->
      if err?
        JName.remove { name: username }, ->
          callback err
        return yes

    # Create JName for new username
    name    = new JName
      name  : username
      slugs : [
        constructorName : 'JUser'
        collectionName  : 'jUsers'
        slug            : username
        usedAsPath      : 'username'
      ]

    name.save (err) =>

      return  if err?

        # If failed to save with duplicate error, return a custom error
        if err?.code is 11000
          callback new KodingError 'Username is not available!'
        else
          callback err

      # Find the JUser assigned to this JAccount
      @fetchUser (err, user) =>
        return  if hasError err

        # Update it's username field too
        user.update { $set: { username, oldUsername } }, (err) =>
          return  if hasError err

          # Update profile.nickname
          @update { $set: { 'profile.nickname': username } }, (err) =>
            return  if hasError err

            # Emit the change, let the whole system knows
            change = { oldUsername, username, isRegistration }
            @constructor.emit 'UsernameChanged', change

            callback null

            # Free up the old username
            JName.remove { name: oldUsername }, (err) ->
              console.warn '[JAccount.changeUsername]', err  if err?

  fetchGroups: secure (client, options, callback) ->
    [callback, options] = [options, callback]  unless callback
    options       ?= {}
    JGroup        = require './group'
    { groupBy }   = require 'underscore'
    { delegate }  = client.connection
    isMine        = @equals delegate
    edgeSelector  =
      sourceName  : 'JGroup'
      targetId    : @getId()
      as          : 'member'
    edgeFields    =
      sourceId    : 1
      as          : 1
    edgeOptions   =
      sort        : options.sort  or { timestamp: -1 }
      limit       : options.limit or 20
      skip        : options.skip  or 0
    Relationship.someData edgeSelector, edgeFields, options, (err, cursor) ->
      if err then callback err
      else
        cursor.toArray (err, docs) ->
          if err then callback err
          else unless docs
            callback null, []
          else
            groupedDocs = groupBy docs, 'sourceId'
            targetSelector = { _id: { $in: (doc.sourceId for doc in docs) } }
            targetSelector.visibility = 'visible'  unless isMine
            JGroup.all targetSelector, (err, groups) ->
              if err then callback err
              else callback null, groups.map (group) ->
                roles = (doc.as for doc in groupedDocs[group.getId()])
                return { group, roles }


  @verifyEmailByUsername = secure (client, username, callback) ->
    { connection:{ delegate }, sessionToken } = client
    unless delegate.can 'verify-emails'
      callback new KodingError 'Access denied'
    else
      JUser = require './user'
      JUser.one { username }, (err, user) ->
        return  callback err if err
        return  callback new Error 'User is not found' unless user
        user.confirmEmail (err) ->
          return callback new Error 'An error occurred while confirming email' if err
          callback null, yes


  @fetchBlockedUsers = secure ({ connection:{ delegate } }, options, callback) ->
    unless delegate.can 'list-blocked-users'
      return callback new KodingError 'Access denied!'

    selector = { blockedUntil: { $gte: new Date() } }

    options.limit = Math.min options.limit ? 20, 20
    options.skip ?= 0

    fields = { username:1, blockedUntil:1 }

    JUser = require './user'
    JUser.someData selector, fields, options, (err, cursor) ->
      return callback err  if err?
      cursor.toArray (err, users) ->
        return callback err       if err?
        return callback null, []  if users.length is 0

        users.sort (a, b) -> a.username < b.username

        acctSelector = { 'profile.nickname': { $in: users.map (u) -> u.username } }

        JAccount.some acctSelector, {}, (err, accounts) ->
          if err
            callback err
          else
            accounts.sort (a, b) -> a.profile.nickname < b.profile.nickname
            for user, i in users
              accounts[i].blockedUntil = users[i].blockedUntil
            callback null, accounts


  @findSuggestions = (client, seed, options, callback) ->
    { limit, blacklist, skip } = options
    ### TODO:
    It is highly dependent to culture and there are even onces w/o the concept
    of first and last names. For now we assume last part of the seed is the lastname
    and the whole except last part is the first name. Not ideal but covers more
    than previous implementation. This implementation would fail if I type my
    two firstnames only, it will assume second part is my lastname.
    Ideal solution is to check the seed against firstName + ' ' + lastName instead of
    deciding ourselves which parts of the search are for first or last name.
    MongoDB 2.4 and bongo implementation of aggregate required to use $concat
    ###
    names = seed.toString().split('/')[1].replace(/[\\^]/g, '').split ' '
    names.push names.first if names.length is 1
    @some {
      $or : [
          ({ 'profile.nickname'  : seed })
          ({ 'profile.firstName' : new RegExp '^'+names.slice(0, -1).join(' '), 'i' })
          ({ 'profile.lastName'  : new RegExp '^'+names.last, 'i' })
        ],
      _id     :
        $nin  : blacklist
      type    :
        $in   : ['registered', null]
    }, {
      skip
      limit
      sort    : { 'profile.firstName' : 1 }
    }, callback


  setEmailPreferences: (user, prefs, callback) ->
    current = user.getAt('emailFrequency') or {}
    Object.keys(prefs).forEach (granularity) ->
      state = prefs[granularity]
      current[granularity] = state# then 'instant' else 'never'

    user.update { $set: { emailFrequency: current } }, (err) ->
      return callback err  if err

      callback null

      emailFrequency =
        global    : current.global
        marketing : current.marketing

      Tracker.identify user.username, { emailFrequency }

  setEmailPreferences$: secure (client, prefs, callback) ->
    JUser = require './user'
    JUser.fetchUser client, (err, user) =>
      if err
        callback err
      else
        @setEmailPreferences user, prefs, callback


  isEmailVerified: (callback) ->
    @fetchUser (err, user) ->
      return callback err if err
      callback null, (user?.status is 'confirmed')

  markUserAsExempt: secure (client, exempt, callback) ->
    { delegate } = client.connection
    return callback new KodingError 'Access denied'  unless delegate.can 'flag', this
    return @markUserAsExemptUnsafe client, exempt, callback

  markUserAsExemptUnsafe: (client, exempt, callback) ->
    # mark user as troll in social api
    @markUserAsExemptInSocialAPI client, exempt, (err, data) =>
      return callback new ApiError err  if err
      op = { $set: { isExempt: exempt } }

      notifyOptions =
        account : client.connection.delegate
        group   : client.context.group
        target  : 'account'

      @updateAndNotify notifyOptions, op, (err, result) =>
        return callback err  if err
        @isExempt = exempt
        callback null, result

  markUserAsExemptInSocialAPI: (client, exempt, callback) ->
    { markAsTroll, unmarkAsTroll } = require './socialapi/requests'
    @createSocialApiId (err, accountId) ->
      return callback err  if err
      return callback new KodingError 'account id is not set'  unless accountId

      if exempt
        markAsTroll { accountId }, callback
      else
        unmarkAsTroll { accountId }, callback


  updateFlags: secure (client, flags, callback) ->
    { delegate } = client.connection
    if delegate.can 'flag', this
      @update { $set: { globalFlags: flags } }, callback
    else
      callback new KodingError 'Access denied'

  fetchUserByAccountIdOrNickname:(accountIdOrNickname, callback) ->

    kallback = (err, account) ->
      return callback err if err
      JUser = require './user'
      JUser.one { username: account.profile.nickname }, (err, user) ->
        callback err, { user, account }


    JAccount.one { 'profile.nickname' : accountIdOrNickname }, (err, account) ->
      return kallback err, account if account
      JAccount.one  { _id : accountIdOrNickname }, (err, account) ->
        return kallback err, account if account
        callback new KodingError 'Account not found'


  blockUser: secure (client, accountIdOrNickname, durationMillis, callback) ->
    { delegate } = client.connection
    if delegate.can('flag', this) and accountIdOrNickname? and durationMillis?
      @fetchUserByAccountIdOrNickname accountIdOrNickname, (err, { user, account }) ->
        return callback err if err
        blockedDate = new Date(Date.now() + durationMillis)
        account.sendNotification 'UserBlocked', { blockedDate }
        user.block blockedDate, callback
    else
      callback new KodingError 'Access denied'

  unblockUser: secure (client, accountIdOrNickname, callback) ->
    { delegate } = client.connection
    if delegate.can('flag', this) and accountIdOrNickname?
      @fetchUserByAccountIdOrNickname accountIdOrNickname, (err, { user }) ->
        return callback err if err
        user.unblock callback
    else
      callback new KodingError 'Access denied'

  checkFlag: (flagToCheck) ->
    flags = @getAt('globalFlags')
    if flags
      if 'string' is typeof flagToCheck
        return flagToCheck in flags
      else
        for flag in flagToCheck
          if flag in flags
            return yes
    return no

  isDummyAdmin = (nickname) -> !!(nickname in dummyAdmins)

  @getFlagRole = -> 'owner'

  # WARNING! Be sure everything is safe when you change anything in this function
  can:(action, target) ->
    switch action
      when 'delete'
        # Users can delete their stuff but super-admins can delete all of them ಠ_ಠ
        @profile.nickname in dummyAdmins or target?.originId?.equals @getId()
      when 'flag', 'reset guests', 'reset groups', 'administer names',         \
           'administer url aliases', 'administer accounts', 'search-by-email', \
           'migrate-koding-users', 'list-blocked-users', 'verify-emails',      \
           'bypass-validations'
        @profile.nickname in dummyAdmins

  fetchRoles: (group, callback) ->
    Relationship.someData {
      targetId: group.getId()
      sourceId: @getId()
    }, { as:1 }, (err, cursor) ->
      if err
        callback err
      else
        cursor.toArray (err, roles) ->
          if err
            callback err
          else
            roles = (roles ? []).map (role) -> role.as
            roles.push 'guest' unless roles.length
            callback null, roles

  fetchRole: secure ({ connection }, callback) ->

    if isDummyAdmin connection.delegate.profile.nickname
      callback null, 'super-admin'
    else
      callback null, 'regular'

  # temp dummy stuff ends


  modify: secure (client, fields, callback) ->

    allowedFields = [
      'preferredKDProxyDomain'
      'profile.about'
      'profile.description'
      'profile.ircNickname'
      'profile.firstName'
      'profile.lastName'
      'profile.avatar'
      'profile.experience'
      'profile.experiencePoints'
      'locationTags'
      'shareLocation'
    ]

    objKeys = Object.keys(fields)

    for objKey in objKeys
      if objKey not in allowedFields
        return callback new KodingError 'Modify fields is not valid'

    if @equals(client.connection.delegate)
      op = { $set: fields }

      notifyOptions =
        account : client.connection.delegate
        group   : client?.context?.group
        target  : 'account'

      @updateAndNotify notifyOptions, op, (err) =>

        firstName = fields['profile.firstName']
        lastName  = fields['profile.lastName']

        Tracker.identify @getAt('profile.nickname'), { firstName, lastName }

        SocialAccount = require './socialapi/socialaccount'
        SocialAccount.update {
          id            : @socialApiId
          nick          : @profile.nickname
          settings      : { shareLocation: fields.shareLocation }
        }, callback

    else
      callback new KodingError 'Access denied'


  getFullName: ->
    { firstName, lastName } = @data.profile
    return "#{firstName} #{lastName}"

  fetchOrCreateAppStorage: (options, callback) ->

    { appId, version } = options
    return callback 'version and appId must be set!' unless appId and version

    query = { accountId : @getId() }
    JCombinedAppStorage.one query, (err, storage) =>
      return callback err            if err
      return callback null, storage  if storage?.bucket?[appId]

      @createAppStorage options, (err, newStorage) ->
        return callback err  if err
        callback null, newStorage


  createAppStorage: (options, callback) ->

    { appId, version, data } = options

    unless appId
      return callback new KodingError 'appId is not set!'

    accountId = @getId()
    options   = { accountId, data }

    JCombinedAppStorage.upsert appId, options, (err, storage) =>
      # recursive call in case of unique index error
      return @createAppStorage options, callback  if err?.code is 11000
      return callback err, storage


  fetchAppStorage$: secure (client, options, callback) ->

    unless client?.connection?.delegate
      return callback 'Not a valid session'

    unless @equals client.connection.delegate
      return callback 'Attempt to access unauthorized application storage'

    @fetchOrCreateAppStorage options, callback

  fetchUser:(callback) ->
    JUser = require './user'
    if /^guest-/.test @profile.nickname
      user = new JUser()
      user.username = @profile.nickname
      return callback null, user

    JUser.one { username: @profile.nickname }, callback

  pushNotification: secure (client, contents, callback) ->
    sender = client?.connection?.delegate
    unless sender
      return callback new KodingError 'Not a valid session'

    unless contents.receiver
      return callback new KodingError 'Receiver is not set'

    # inject sender nick
    contents.sender = sender.profile?.nickname
    unless contents.sender
      return callback new KodingError 'Sender is not set'


    JAccount.one { 'profile.nickname': contents.receiver }, (err, receiver) ->
      return callback err  if err

      contents.group = client?.context?.group or 'koding'

      receiver.sendNotification 'notificationFromOtherAccount', contents

      return callback null


  sendNotification: (event, contents) ->
    @createSocialApiId (err, socialApiId) =>
      return console.error 'Could not send notification to account:', err  if err

      message = {
        account: { id: socialApiId, nick: @profile.nickname }
        eventName: 'social'
        body:
          contents : contents
          event    : event
          context  : contents?.group or 'koding'
      }

      require('./socialapi/requests').dispatchEvent 'dispatcher_notify_user', message, (err) ->
        console.error '[dispatchEvent][notify_user]', err if err # do not cause trailing parameters


  cancelRequest: secure (client, slug, callback) ->
    options =
      targetOptions :
        selector    :
          status    : 'pending'
    JGroup = require './group'

    JGroup.one { slug }, (err, group) ->
      return callback err  if err

      @fetchInvitationRequests { sourceId: group.getId() }, options, (err, [request]) ->
        return callback err                                  if err
        return callback 'could not find invitation request'  unless request
        request.remove callback

  fetchInvitationByGroupSlug:(slug, callback) ->
    options =
      targetOptions :
        selector    : { status: 'sent', group: slug }
    @fetchInvitations {}, options, (err, [invite]) ->
      return callback err                          if err
      return callback 'could not find invitation'  unless invite

      JGroup = require './group'
      JGroup.one { slug }, (err, groupObj) ->
        return callback err  if err
        callback null, { invite, group: groupObj }

  acceptInvitation: secure (client, slug, callback) ->
    @fetchInvitationByGroupSlug slug, (err, { invite, group }) =>
      return callback err  if err
      groupObj.approveMember this, (err) ->
        return callback err  if err
        invite.update { $set: { status:'accepted' } }, callback

  ignoreInvitation: secure (client, slug, callback) ->
    @fetchInvitationByGroupSlug slug, (err, { invite }) ->
      return callback err  if err
      invite.update { $set: { status:'ignored' } }, callback

  @byRelevance$ = permit 'list members',
    success: (client, seed, options, callback) ->
      if options.byEmail
        account = client.connection.delegate
        if account.can 'search-by-email'
          JUser = require './user'
          JUser.one { email:seed }, (err, user) ->
            return callback err, []  if err? or not user?
            user.fetchOwnAccount (err, account) ->
              return callback err  if err?
              callback null, [account]
        else
          return callback new KodingError 'Access denied'
      else
        @byRelevance client, seed, options, callback

  fetchMyPermissions: secure (client, callback) ->
    @fetchMyPermissionsAndRoles client, (err, permissions, roles) ->
      callback err, permissions

  fetchMyPermissionsAndRoles: secure (client, callback) ->
    JGroup = require './group'

    slug = client.context.group ? 'koding'
    JGroup.one { slug }, (err, group) =>
      return callback err  if err
      return callback new KodingError 'group not found'  unless group

      kallback = (err, roles) =>
        return callback err  if err

        @fetchUser (err, user) ->
          return callback err  if err
          return callback new KodingError 'User not found'  unless user

          userId = user._id

          { flatten } = require 'underscore'

          if 'admin' in roles

            perms = Protected.permissionsByModule
            callback null, { permissions: (flatten perms), roles, userId }

          else

            group.fetchPermissionSetOrDefault (err, permissionSet) ->
              return callback err if err

              perms = (perm.permissions.slice() for perm in permissionSet.permissions \
                when perm.role in roles or 'admin' in roles)

              callback null, { permissions: (flatten perms), roles, userId }

      group.fetchMyRoles client, kallback

  ## NEWER IMPLEMENATION: Fetch ids from graph db, get items from document db.

  unlinkOauth: secure (client, provider, callback) ->

    if not client or not @equals client.connection.delegate
      return callback new KodingError 'Access denied'

    JForeignAuth = require './foreignauth'

    @fetchUser (err, user) ->
      return callback err  if err
      return callback new KodingError 'User not found'  unless user

      JForeignAuth.remove {
        username: user.username
        group: client.context.group
        provider
      }, (err) ->
        return callback err  if err

        foreignAuth = {}
        foreignAuth[provider] = no
        Tracker.identify user.username, { foreignAuth }

        callback null

  # we are using this in sorting members list..
  updateMetaModifiedAt: (callback) ->
    @update { $set: { 'meta.modifiedAt': new Date } }, callback


  fetchEmail: (callback) ->

    @fetchUser (err, user) ->
      return callback err  if err
      callback null, user?.email

  fetchEmail$: secure (client, callback) ->
    { delegate } = client.connection
    isMine     = @equals delegate
    if isMine
      @fetchEmail callback
    else
      callback new KodingError 'Access denied'


  @fetchEmailsByUsername = permit 'grant permissions',
    success: (client, usernames = [], callback) ->
      return callback null, []  unless usernames.length

      selector = { username: { $in: usernames } }
      options  = { email: 1, username: 1 }

      JUser = require './user'
      JUser.someData selector, options, (err, cursor) ->
        return callback err  if err

        cursor.toArray (err, list) ->
          return callback err  if err

          data            = {}
          data[username]  = email  for { username, email } in list

          callback null, data


  fetchEmailAndStatus: secure (client, callback) ->
    @fetchFromUser client, ['email', 'status'], callback

  fetchEmailFrequency: secure (client, callback) ->
    @fetchFromUser client, 'emailFrequency', callback

  fetchOAuthInfo: secure (client, callback) ->
    JForeignAuth = require './foreignauth'
    JForeignAuth.fetchData client, callback

  fetchFromUser: secure (client, key, callback) ->
    { delegate } = client.connection
    isMine       = @equals delegate

    return callback new KodingError 'Access denied'  unless isMine

    @fetchUser (err, user) ->
      return callback err  if err
      return callback new KodingError 'User not found'  unless user

      if Array.isArray key
        results = {}
        for k in key
          results[k] = user.getAt k

        callback null, results
      else
        callback null, user.getAt key



  expireSubscription: secure ({ connection }, callback) ->
    if KONFIG.environment is 'production'
      return callback new KodingError 'permission denied'

    { expireSubscription } = require './socialapi/requests'
    expireSubscription connection.delegate.getId(), callback


  ###*
   * Fetches one time access token from active session
   * If accesstoken used before (not exists) it creates
   * and returns new one while updating the session.
   *
   * @param  {Function(err, token)} callback
  ###
  fetchOtaToken: secure (client, callback) ->

    { sessionToken } = client

    errorCallback = ->
      callback new KodingError 'Invalid session'

    return errorCallback()  unless sessionToken

    JSession = require './session'
    uuid = require 'uuid'

    JSession.one { clientId: sessionToken }, (err, session) ->

      if err or not session or session.isGuestSession()
        return errorCallback()

      [otaToken] = uuid.v4().split '-'
      session.update { $set: { otaToken } }, (err) ->
        if err then errorCallback()
        else callback null, otaToken


  ###*
   * Internal helper for following 2Factor authentication methods
   * Makes sure session is valid and returns JUser if possible.
   *
   * @param {function(err, [JUser])} callback
  ###
  _fetchUser = (client, callback) ->

    unless client?.connection?.delegate
      return callback new KodingError 'Invalid session'

    account = client.connection.delegate
    account.fetchUser (err, user) ->
      return callback new KodingError 'User not found'  unless user

      callback null, user


  ###*
   * Generates 2 Factor Authentication key which can be used to
   * setup Google Authenticator application in your mobile device.
   *
   * This method only generates the key by using `speakeasy` npm package
   *
   * @param {function (err, [{key: string, qrcode: string}])} callback
  ###
  generate2FactorAuthKey: secure (client, callback) ->

    _fetchUser client, (err, user) ->
      return callback err  if err

      if user.getAt 'twofactorkey'
        return callback new KodingError \
          '2Factor authentication already in use.', 'ALREADY_INUSE'

      speakeasy        = require 'speakeasy'
      generatedKey     = speakeasy.generate_key
        name           : "Koding - @#{user.username}"
        length         : 16
        symbols        : yes
        google_auth_qr : yes

      { base32: key, google_auth_qr: qrcode } = generatedKey

      callback null, { key, qrcode }


  ###*
   * Enable/Disable 2 Factor Authentication with provided auth `key`,
   * `verification` and user's current `password`.
   *
   * Enabling:
   * After verifying the current password, it tries to verify provided auth
   * key with verification then updates `JUser.twofactorkey` field with the
   * provided auth key.
   *
   * Disabling: (if `disable` is true)
   * It verifies the current password, then removes `JUser.twofactorkey` field
   *
   * @param {{key: string, verification: string,
   *          password: string, [disable: bool]}} options
   * @param {function (err)} callback
  ###
  setup2FactorAuth: secure (client, options, callback) ->

    username = @profile.nickname

    _fetchUser client, (err, user) ->
      return callback err  if err

      { disable, password } = options

      if not disable and user.getAt 'twofactorkey'
        return callback new KodingError '2Factor authentication already in use.'

      unless user.checkPassword password
        return callback new KodingError 'Password is invalid'

      if disable
        user.update { $unset: { twofactorkey: '' } }, (err) ->
          options =
            subject : Tracker.types.USER_DISABLED_2FA
          Tracker.identifyAndTrack username, options
          callback err

        return

      { key, verification } = options

      speakeasy    = require 'speakeasy'
      generatedKey = speakeasy.totp { key, encoding: 'base32' }

      if generatedKey isnt verification
        return callback new KodingError \
          'Verification failed for provided code.', 'INVALID_TOKEN'

      user.update { $set: { twofactorkey: key } }, (err) ->
        options =
          subject : Tracker.types.USER_ENABLED_2FA
        Tracker.identifyAndTrack username, options
        callback err


  fetchMySessions: secure (client, options, callback) ->

    # check if requester is the owner of the account
    unless @equals client.connection.delegate
      return callback new KodingError 'Access denied.'

    { sessionToken } = client
    return callback new KodingError 'Invalid session.'  unless sessionToken

    { skip, limit, sort } = options
    skip  ?= 0
    limit ?= 10
    sort  ?= { '_id' : -1 }

    username = @profile.nickname
    selector = { username }
    options  = { limit, skip, sort }
    JSession = require './session'
    JSession.some selector, options, callback


  destroy$: secure (client, password, callback) ->

    { delegate } = client.connection
    { profile: { nickname } } = delegate

    if nickname isnt @getAt 'profile.nickname'
      return callback new KodingError \
        'You are trying to delete the account that does not belong to you'

    checkUserPassword delegate, password, (err) =>

      return callback new KodingError err  if err

      @destroy client, callback


  destroy: (client, callback) ->

    @fetchRelativeGroups { roles: ['owner'] }, (err, groups) =>

      # filter out the koding team
      groups = groups.filter (group) -> group.slug isnt 'koding'

      if groups.length > 1
        return callback new KodingError 'You cannot delete your account when you have ownership in other team', groups

      kallback = (label, next, err) ->

        errors.push { label, err }  if err
        next()

      [ group ] = groups

      errors = []

      username = @getAt 'profile.nickname'
      accountId = @getId()

      # delete resources of the account, team and account itself
      queue = [
        (next) =>
          # delete user's resources (stack templates, stacks, machines)
          ComputeProvider = require './computeproviders/computeprovider'
          ComputeProvider.destroyAccountResources this, next

        (next) ->
          # deny from all machines that are shared with the account
          JMachine = require './computeproviders/machine'
          selector = { 'users.username' : username }
          JMachine.some selector, {}, (err, machines) ->

            return next()  unless machines

            deleteMachines = machines.map (machine) -> (fin) ->
              machine.deny client, fin

            async.parallel deleteMachines, ->
              kallback 'JMachine', next, err

        (next) ->
          # delete the credentials that are associated with the account
          JCredential = require './computeproviders/credential'
          JCredential.some$ client, { originId: accountId }, {}, (err, credentials) ->

            return next()  unless credentials

            deleteCredentials = credentials.map (credential) -> (fin) ->
              credential.delete client, fin

            async.parallel deleteCredentials, ->
              kallback 'JCredential', next, err

        (next) ->
          return next()  unless group
          group.destroy client, (err) ->
            kallback 'GroupDestroy', next, err

        (next) ->
          # delete apitokens
          JApiToken = require './apitoken'
          JApiToken.remove { originId: accountId }, ->
            kallback 'JApiToken', next, err


        (next) ->
          # delete invitations
          JInvitation = require './invitation'
          JInvitation.remove { inviterId: accountId }, (err) ->
            kallback 'JInvitation', next, err

        (next) ->
          JUser = require './user'
          JUser.unregister client, username, (err) ->
            kallback 'JUser', next, err

        (next) =>
          @remove (err) -> kallback 'JAccount', next, err

        (next) ->
          JSession = require './session'
          JSession.remove { username }, (err) ->
            kallback 'JSession', next, err

      ]

      call  = null

      deleteAccount = (cb) ->

        async.series queue, ->

          # execute the callback on the first try
          # even there is an error or not
          if call.getNumRetries() is 0
            callback null

          return  if not errors.length

          cb errors
          errors = []

      call = backoff.call deleteAccount, ->

      call.retryIf (errors) ->

        errors.forEach (error) ->
          console.log "[ACCOUNT_DESTROY_FAILED]: Attempt: #{call.getNumRetries()}
          for #{username} in #{error.label} with error #{error.err}"

        errors.length

      call.setStrategy new backoff.ExponentialStrategy
        initialDelay: 1000
        maxDelay    : 10000

      call.failAfter 2
      call.start()
