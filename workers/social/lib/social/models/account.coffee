jraphical   = require 'jraphical'
KodingError = require '../error'

likeableActivities = ['JCodeSnip', 'JStatusUpdate', 'JDiscussion',
                      'JOpinion', 'JCodeShare', 'JLink', 'JTutorial',
                      'JBlogPost']

module.exports = class JAccount extends jraphical.Module
  log4js          = require "log4js"
  log             = log4js.getLogger("[JAccount]")

  @trait __dirname, '../traits/followable'
  @trait __dirname, '../traits/filterable'
  @trait __dirname, '../traits/taggable'
  @trait __dirname, '../traits/notifying'
  @trait __dirname, '../traits/flaggable'

  JStorage         = require './storage'
  JAppStorage      = require './appstorage'
  JTag             = require './tag'
  CActivity        = require './activity'
  Graph            = require "./graph/graph"
  JName            = require './name'

  @getFlagRole            = 'content'
  @lastUserCountFetchTime = 0

  {ObjectId, Register, secure, race, dash, daisy} = require 'bongo'
  {Relationship} = jraphical
  {permit} = require './group/permissionset'
  Validators = require './group/validators'

  @share()
  Experience =
    company           : String
    website           : String
    position          : String
    type              : String
    fromDate          : String
    toDate            : String
    description       : String
    # endorsements      : [
    #       endorser    : String
    #       title       : String
    #       text        : String
    #     ]
  @set
    softDelete          : yes
    emitFollowingActivities : yes # create buckets for follower / followees
    tagRole             : 'skill'
    taggedContentRole   : 'developer'
    indexes:
      'profile.nickname' : 'unique'
      isExempt           : 1
      type               : 1
    sharedEvents    :
      static        : [
        { name: 'AccountAuthenticated' } # TODO: we need to handle this event differently.
        { name : "RemovedFromCollection" }
      ]
      instance      : [
        { name: 'updateInstance' }
        { name: 'notification' }
        { name : "RemovedFromCollection" }
      ]
    sharedMethods :
      static: [
        'one'
        'some'
        'cursor'
        'each'
        'someWithRelationship'
        'someData'
        'getAutoCompleteData'
        'count'
        'byRelevance'
        'fetchVersion'
        'reserveNames'
        'impersonate'
        'fetchBlockedUsers'
        'fetchCachedUserCount'
      ]
      instance: [
        'modify'
        'follow'
        'unfollow'
        'fetchFollowersWithRelationship'
        'countFollowersWithRelationship'
        'countFollowingWithRelationship'
        'fetchFollowingWithRelationship'
        'fetchTopics'
        'fetchMounts'
        'fetchActivityTeasers'
        'fetchRepos'
        'fetchDatabases'
        'fetchMail'
        'fetchNotificationsTimeline'
        'fetchActivities'
        'fetchAppStorage'
        'addTags'
        'fetchLimit'
        'fetchLikedContents'
        'fetchFollowedTopics'
        'setEmailPreferences'
        'glanceMessages'
        'glanceActivities'
        'fetchRole'
        'fetchAllKites'
        'flagAccount'
        'unflagAccount'
        'isFollowing'
        'fetchFeedByTitle'
        'updateFlags'
        'fetchGroups'
        'fetchGroupRoles'
        'setStaticPageVisibility'
        'addStaticPageType'
        'removeStaticPageType'
        'setHandle'
        'setAbout'
        'fetchAbout'
        'setStaticPageTitle'
        'setStaticPageAbout'
        'addStaticBackground'
        'setBackgroundImage'
        'fetchGroupsWithPendingInvitations'
        'fetchGroupsWithPendingRequests'
        'cancelRequest'
        'acceptInvitation'
        'ignoreInvitation'
        'fetchMyGroupInvitationStatus'
        'fetchMyPermissions'
        'fetchMyPermissionsAndRoles'
        'fetchMyFollowingsFromGraph'
        'fetchMyFollowersFromGraph'
        'blockUser'
        'unblockUser'
        'sendEmailVMTurnOnFailureToSysAdmin'
        'fetchRelatedTagsFromGraph'
        'fetchRelatedUsersFromGraph'
        'fetchDomains'
        'fetchDomains'
        'unlinkOauth'
        'changeUsername'
        'markUserAsExempt'
        'checkFlag'
        'userIsExempt'
        'checkGroupMembership'
        'getOdeskAuthorizeUrl'
        'fetchStorage'
        'fetchStorages'
        'store'
        'unstore'
        'isEmailVerified'
      ]
    schema                  :
      skillTags             : [String]
      locationTags          : [String]
      systemInfo            :
        defaultToLastUsedEnvironment :
          type              : Boolean
          default           : yes
      # counts                : Followable.schema.counts
      counts                :
        followers           :
          type              : Number
          default           : 0
        following           :
          type              : Number
          default           : 0
        topics              :
          type              : Number
          default           : 0
        likes               :
          type              : Number
          default           : 0
      environmentIsCreated  : Boolean
      type                  :
        type                : String
        enum                : ['invalid account type',[
                                'registered'
                                'unregistered'
                                'deleted'
                              ]]
        default             : 'unregistered'
      profile               :
        about               : String
        nickname            :
          type              : String
          validate          : require('./name').validateName
          set               : (value)-> value.toLowerCase()
        hash                : String
        ircNickname         : String
        firstName           :
          type              : String
          required          : yes
          default           : 'a koding'
        lastName            :
          type              : String
          default           : 'user'
        description         : String
        avatar              : String
        status              : String
        experience          : String
        experiencePoints    :
          type              : Number
          default           : 0
        lastStatusUpdate    : String
      referrerUsername      : String
      isExempt              : # is a troll ?
        type                : Boolean
        default             : false
      globalFlags           : [String]
      meta                  : require 'bongo/bundles/meta'
      onlineStatus          :
        type                : String
        enum                : ['invalid status',['online','offline','away','busy']]
        default             : 'online'

    relationships           : ->
      JPrivateMessage = require './messages/privatemessage'

      follower      :
        as          : 'follower'
        targetType  : JAccount

      activity      :
        as          : 'activity'
        targetType  : "CActivity"

      privateMessage:
        as          : ['recipient','sender']
        targetType  : JPrivateMessage

      appStorage    :
        as          : 'appStorage'
        targetType  : "JAppStorage"

      storage       :
        as          : 'storage'
        targetType  : 'JStorage'

      tag:
        as          : 'skill'
        targetType  : "JTag"

      about:
        as          : 'about'
        targetType  : 'JMarkdownDoc'

      content       :
        as          : 'creator'
        targetType  : [
          "CActivity", "JStatusUpdate", "JCodeSnip", "JComment", "JReview"
          "JDiscussion", "JOpinion", "JCodeShare", "JLink", "JTutorial",
          "JBlogPost"
        ]

      vm            :
        as          : 'owner'
        targetType  : 'JVM'

      domain        :
        as          : 'owner'
        targetType  : 'JDomain'

      proxyFilter   :
        as          : 'owner'
        targetType  : 'JProxyFilter'

      referrer      :
        targetType  : 'JReferral'
        as          : 'referrer'
      referred      :
        targetType  : 'JReferral'
        as          : 'referred'
      invitation    :
        as          : 'owner'
        targetType  : 'JInvitation'

      invitationRequest :
        as          : 'owner'
        targetType  : 'JInvitationRequest'

  constructor:->
    super
    @notifyOriginWhen 'PrivateMessageSent', 'FollowHappened'
    @notifyGroupWhen 'FollowHappened'


  checkGroupMembership: secure (client, groupName, callback)->
    {delegate} = client.connection
    JGroup = require "./group"
    JGroup.one {slug : groupName}, (err, group)->
      return callback new KodingError "An error occured!" if err
      return callback null, no unless group

      Relationship.one {
        as          : 'member'
        targetId    : delegate.getId()
        sourceId    : group.getId()
      }, (err, relation)=>
        return callback new KodingError "An error occured!" if err
        return callback null, relation?

  changeUsername: (options, callback = (->)) ->
    if 'string' is typeof options
      username = options
    else
      { username, mustReauthenticate, isRegistration } = options

    oldUsername = @profile.nickname

    if username is oldUsername
    then return callback new KodingError "Username was not changed!"

    freeOldUsername = ->
      JName.remove name: oldUsername, (err) ->
        return callback err  if err
        callback null

    handleErr = (err) ->
      JName.remove name: username, (err) ->
        return callback err  if err

      if err.code is 11000
      then return callback new KodingError 'Username is not available!'
      else if err?
      then return callback err

    unless @constructor.validateAt 'profile.nickname', username
    then return callback new KodingError 'Invalid username!'

    name = new JName
      name: username
      slugs: [
        constructorName : 'JUser'
        collectionName  : 'jUsers'
        slug            : username
        usedAsPath      : 'username'
      ]

    name.save (err) =>
      return handleErr err  if err

      @fetchUser (err, user) =>
        return callback err  if err

        user.update { $set: { username, oldUsername } }, (err) =>
          if err then handleErr err, callback
          else
            @update { $set: 'profile.nickname': username }, (err) =>
              if err then handleErr err
              else
                change = {
                  oldUsername, username, mustReauthenticate, isRegistration
                }
                @sendNotification 'UsernameChanged', change  if mustReauthenticate
                @constructor.emit 'UsernameChanged', change
                freeOldUsername()

  changeUsername$: secure (client, options, callback) ->

    {delegate} = client.connection

    if @type is 'unregistered' or not delegate.equals this
    then return callback new KodingError 'Access denied'

    options = username: options  if 'string' is typeof options

    options.mustReauthenticate = yes

    @changeUsername options, callback

  checkPermission: (target, permission, callback)->
    JPermissionSet = require './group/permissionset'
    client =
      context     : { group: target.slug }
      connection  : { delegate: this }
    advanced =
      if Array.isArray permission then permission
      else JPermissionSet.wrapPermission permission
    JPermissionSet.checkPermission client, advanced, target, callback

  @renderHomepage: require '../render/profile.coffee'

  @fetchCachedUserCount: (callback)->
    if (Date.now() - @lastUserCountFetchTime)/1000 < 60
      return callback null, @cachedUserCount
    JAccount.count type:'registered', (err, count)=>
      return callback err if err
      @lastUserCountFetchTime = Date.now()
      @cachedUserCount = count
      callback null, count

  fetchHomepageView:(account, callback)->

    JAccount.renderHomepage
      renderedAccount : account
      account         : this
      isLoggedIn      : account.type is 'unregistered'
    , callback


  setHandle: secure (client, data, callback)->
    {delegate}      = client.connection
    {service,value} = data
    selector        = "profile.handles."+service
    isMine          = @equals delegate
    if isMine and service in ['twitter','github']
      value     = null if value is ''
      operation = $set: {}
      operation.$set[selector] = value
      @update operation, callback
    else
      callback? new KodingError 'Access denied'

  fetchGroups: secure (client, options = {}, callback)->
    JGroup        = require './group'
    {groupBy}     = require 'underscore'
    {delegate}    = client.connection
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
    Relationship.someData edgeSelector, edgeFields, options, (err, cursor)->
      if err then callback err
      else
        cursor.toArray (err, docs)->
          if err then callback err
          else unless docs
            callback null, []
          else
            groupedDocs = groupBy docs, 'sourceId'
            targetSelector = { _id: $in: (doc.sourceId for doc in docs) }
            targetSelector.visibility = 'visible'  unless isMine
            JGroup.all targetSelector, (err, groups)->
              if err then callback err
              else callback null, groups.map (group)->
                roles = (doc.as for doc in groupedDocs[group.getId()])
                return { group, roles }

  fetchGroupRoles: secure (client, slug, callback)->
    {delegate} = client.connection
    JGroup     = require './group'
    JGroup.fetchIdBySlug slug, (err, groupId)->
      if err then callback err
      else
        selector = {
          sourceId: groupId
          targetId: delegate.getId()
        }
        Relationship.someData selector, {as:1}, (err, cursor)->
          if err then callback err
          else
            cursor.toArray (err, arr)->
              if err then callback err
              else callback null, (doc.as for doc in arr)

  @impersonate = secure (client, nickname, callback)->
    {connection:{delegate}, sessionToken} = client
    unless delegate.can 'administer accounts'
      callback new KodingError 'Access denied'
    else
      JSession = require './session'
      JSession.update {clientId: sessionToken}, $set:{username: nickname}, callback

  @reserveNames =(options, callback)->
    [callback, options] = [options, callback]  unless callback
    options       ?= {}
    options.limit ?= 100
    options.skip  ?= 0
    @someData {}, {'profile.nickname':1}, options, (err, cursor)=>
      if err then callback err
      else
        count = 0
        cursor.each (err, account)=>
          if err then callback err
          else if account?
            {nickname} = account.profile
            JName.claim nickname, 'JUser', 'username', (err, name)=>
              count++
              if err then callback err
              else
                callback err, nickname
                if count is options.limit
                  options.skip += options.limit
                  @reserveNames options, callback

  @fetchVersion =(callback)-> callback null, KONFIG.version

  @fetchBlockedUsers = secure ({connection:{delegate}}, options, callback) ->
    unless delegate.can 'list-blocked-users'
      callback new KodingError 'Access denied!'

    selector = blockedUntil: $gte: new Date()

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

        acctSelector = 'profile.nickname': $in: users.map (u) -> u.username

        JAccount.some acctSelector, {}, (err, accounts)=>
          if err
            callback err
          else
            accounts.sort (a, b) -> a.profile.nickname < b.profile.nickname
            for user, i in users
              accounts[i].blockedUntil = users[i].blockedUntil
            callback null, accounts


  @findSuggestions = (client, seed, options, callback)->
    {limit, blacklist, skip}  = options
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
    names = seed.toString().split('/')[1].replace('^','').split ' '
    names.push names.first if names.length is 1
    @some {
      $or : [
          ( 'profile.nickname'  : seed )
          ( 'profile.firstName' : new RegExp '^'+names.slice(0, -1).join(' '), 'i' )
          ( 'profile.lastName'  : new RegExp '^'+names.last, 'i' )
        ],
      _id     :
        $nin  : blacklist
      type    :
        $in   : ['registered', null]
    },{
      skip
      limit
      sort    : 'profile.firstName' : 1
    }, callback

  @getAutoCompleteData = (fieldString, queryString, callback)->
    query = {}
    desiredData = {}
    query[fieldString] = RegExp queryString, 'i'
    desiredData[fieldString] = yes
    @someData query, desiredData, (err, cursor)->
      cursor.toArray (err, docs)->
        results = []
        for doc in docs
          results.push doc.profile.fullname
        callback err, results

  setEmailPreferences: (user, prefs, callback)->
    current = user.getAt('emailFrequency') or {}
    Object.keys(prefs).forEach (granularity)->
      state = prefs[granularity]
      state = false if state not in [true, false]
      current[granularity] = state# then 'instant' else 'never'
    user.update {$set: emailFrequency: current}, callback

  setEmailPreferences$: secure (client, prefs, callback)->
    JUser = require './user'
    JUser.fetchUser client, (err, user)=>
      if err
        callback err
      else
        @setEmailPreferences user, prefs, callback

  glanceMessages: secure (client, callback)->

  glanceActivities: secure (client, activityId, callback)->
    [callback, activityId] = [activityId, callback] unless callback
    {delegate} = client.connection
    unless @equals delegate
      callback new KodingError 'Access denied'
    else
      selector = {'data.flags.glanced' : $ne : yes}
      selector.targetId = activityId if activityId
      @fetchActivities selector, (err, activities)->
        if err
          callback err
        else
          queue = activities.map (activity)->->
            activity.mark client, 'glanced', -> queue.fin()
          dash queue, callback

  fetchLikedContents: secure ({connection}, options, selector, callback)->

    {delegate} = connection
    [callback, selector] = [selector, callback] unless callback

    selector            or= {}
    selector.as           = 'like'
    selector.targetId     = @getId()
    selector.sourceName or= $in: likeableActivities

    Relationship.some selector, options, (err, contents)=>
      if err then callback err, []
      else if contents.length is 0 then callback null, []
      else
        teasers = []
        collectTeasers = race (i, root, fin)->
          root.fetchSource (err, post)->
            if err
              callback err
              fin()
            else if not post
              console.warn "Source does not exists:", root.sourceName, root.sourceId
              fin()
            else
              post.fetchTeaser (err, teaser)->
                if not err and teaser then teasers.push(teaser)
                fin()
        , -> callback null, teasers
        collectTeasers node for node in contents

  # Update broken counts for user
  updateCounts:->

    # Like count
    Relationship.count
      as         : 'like'
      targetId   : @getId()
      sourceName : $in: likeableActivities
    , (err, count)=>
      @update ($set: 'counts.likes': count), ->

    # Member Following count
    Relationship.count
      as         : 'follower'
      targetId   : @getId()
      sourceName : 'JAccount'
    , (err, count)=>
      @update ($set: 'counts.following': count), ->

    # Tag Following count
    Relationship.count
      as         : 'follower'
      targetId   : @getId()
      sourceName : 'JTag'
    , (err, count)=>
      @update ($set: 'counts.topics': count), ->

  dummyAdmins = [ "sinan", "devrim", "gokmen", "chris", "fatihacet", "arslan",
                  "sent-hil", "kiwigeraint", "cihangirsavas", "leventyalcin",
                  "samet" ]

  userIsExempt: (callback)->
    # console.log @isExempt, this
    callback null, @isExempt

  # returns troll users ids
  @getExemptUserIds: (callback)->
    JAccount.someData {isExempt:true}, {_id:1}, (err, cursor)->
      cursor.toArray (err, data)->
        if err
          return callback err, null
        callback null, (i._id for i in data)

  isEmailVerified: (callback)->
    @fetchUser (err, user)->
      return callback err if err
      callback null, (user.status is "confirmed")

  markUserAsExempt: secure (client, exempt, callback)->
    {delegate} = client.connection
    if delegate.can 'flag', this
      @update $set: {isExempt: exempt}, callback
      # this is for backwards comp. will remove later...
      if exempt
        @update {$addToSet: globalFlags: "exempt"}, ()->
      else
        @update {$pullAll: globalFlags: ["exempt"]}, ()->

    else
      callback new KodingError 'Access denied'

  flagAccount: secure (client, flag, callback)->
    {delegate} = client.connection
    JAccount.taint @getId()
    if delegate.can 'flag', this
      @update {$addToSet: globalFlags: flag}, callback
    else
      callback new KodingError 'Access denied'

  unflagAccount: secure (client, flag, callback)->
    {delegate} = client.connection
    JAccount.taint @getId()
    if delegate.can 'flag', this
      @update {$pullAll: globalFlags: [flag]}, callback
    else
      callback new KodingError 'Access denied'

  updateFlags: secure (client, flags, callback)->
    {delegate} = client.connection
    JAccount.taint @getId()
    if delegate.can 'flag', this
      @update {$set: globalFlags: flags}, callback
    else
      callback new KodingError 'Access denied'

  fetchUserByAccountIdOrNickname:(accountIdOrNickname, callback)->

    kallback= (err, account)->
      return callback err if err
      JUser = require './user'
      JUser.one {username: account.profile.nickname}, (err, user)->
        callback err, {user, account}


    JAccount.one { 'profile.nickname' : accountIdOrNickname }, (err, account)->
      return kallback err, account if account
      JAccount.one  { _id : accountIdOrNickname }, (err, account)->
        return kallback err, account if account
        callback new KodingError 'Account not found'


  blockUser: secure (client, accountIdOrNickname, toDate, callback)->
    {delegate} = client.connection
    if delegate.can('flag', this) and accountIdOrNickname? and toDate?
      @fetchUserByAccountIdOrNickname accountIdOrNickname, (err, {user, account})->
        return callback err if err
        blockedDate = new Date(Date.now() + toDate)
        account.sendNotification 'UserBlocked', { blockedDate }
        user.block blockedDate, callback
    else
      callback new KodingError 'Access denied'

  unblockUser: secure (client, accountIdOrNickname, callback)->
    {delegate} = client.connection
    if delegate.can('flag', this) and accountIdOrNickname?
      @fetchUserByAccountIdOrNickname accountIdOrNickname, (err, {user})->
        return callback err if err
        user.unblock callback
    else
      callback new KodingError 'Access denied'

  checkFlag:(flagToCheck)=>
    if flagToCheck is 'exempt'
      return @isExempt
    flags = @getAt('globalFlags')
    if flags
      if 'string' is typeof flagToCheck
        return flagToCheck in flags
      else
        for flag in flagToCheck
          if flag in flags
            return yes
    no

  isDummyAdmin = (nickname)-> !!(nickname in dummyAdmins)

  @getFlagRole =-> 'owner'

  # WARNING! Be sure everything is safe when you change anything in this function
  can:(action, target)->
    switch action
      when 'delete'
        # Users can delete their stuff but super-admins can delete all of them ಠ_ಠ
        @profile.nickname in dummyAdmins or target?.originId?.equals @getId()
      when 'flag', 'reset guests', 'reset groups', 'administer names', \
           'administer url aliases', 'administer accounts', \
           'migrate-koding-users', 'list-blocked-users'
        @profile.nickname in dummyAdmins

  fetchRoles: (group, callback)->
    Relationship.someData {
      targetId: group.getId()
      sourceId: @getId()
    }, {as:1}, (err, cursor)->
      if err
        callback err
      else
        cursor.toArray (err, roles)->
          if err
            callback err
          else
            roles = (roles ? []).map (role)-> role.as
            roles.push 'guest' unless roles.length
            callback null, roles

  fetchRole: secure ({connection}, callback)->

    if isDummyAdmin connection.delegate.profile.nickname
      callback null, "super-admin"
    else
      callback null, "regular"

  fetchAllKites: secure ({connection}, callback)->

    if isDummyAdmin connection.delegate.profile.nickname
      callback null,
        Databases     :
          hosts       : ["cl0", "cl1", "cl2", "cl3"]
        terminal      :
          hosts       : ["cl0", "cl1", "cl2", "cl3"]
    else
      callback new KodingError "Permission denied!"

  # temp dummy stuff ends

  fetchPrivateChannel:(callback)->
    require('bongo').fetchChannel @getPrivateChannelName(), callback

  getPrivateChannelName:-> "private-#{@getAt('profile.nickname')}-private"

  fetchMail:do ->

    collectParticipants = (messages, delegate, callback)->
      fetchParticipants = race (i, message, fin)->
        register = new Register # a register per message...

        query =
          targetName  : 'JPrivateMessage'
          targetId    : message.getId()
          sourceId    :
            $ne       : delegate.getId()

        jraphical.Relationship.cursor query, (err, cursor)->
          return callback err  if err
          message.participants = []
          cursor.each (err, rel)->
            unless rel then fin()
            else
              message.participants.push rel  if register.sign rel.sourceId

      , callback

      fetchParticipants(message) for message in messages when message?

    secure ({connection:{delegate}}, options, callback)->
      [callback, options] = [options, callback] unless callback
      unless @equals delegate
        callback new KodingError 'Access denied'
      else
        options or= {}
        @fetchPrivateMessages {}, options, (err, messages)->
          return callback err, []  if err or messages.length is 0
          collectParticipants messages, delegate, (err)->
            callback err, messages

  fetchTopics: secure (client, query, page, callback)->
    query       =
      targetId  : @getId()
      as        : 'follower'
      sourceName: 'JTag'
    Relationship.some query, page, (err, docs)->
      if err then callback err
      else
        {group} = client.context
        ids = (rel.sourceId for rel in docs)
        selector = _id: $in: ids
        selector.group = group if group isnt 'koding'
        JTag.all selector, (err, tags)->
          callback err, tags

  fetchNotificationsTimeline: secure ({connection}, selector, options, callback)->
    unless @equals connection.delegate
      callback new KodingError 'Access denied'
    else
      @fetchActivities selector, options, @constructor.collectTeasersAllCallback callback

  fetchActivityTeasers : secure ({connection}, selector, options, callback)->

    unless @equals connection.delegate
      callback new KodingError 'Access denied'
    else
      @fetchActivities selector, options, callback

  modify: secure (client, fields, callback) ->
    if @equals(client.connection.delegate) and 'globalFlags' not in Object.keys(fields)
      @update $set: fields, callback

  oldFetchMounts = @::fetchMounts
  fetchMounts: secure (client,callback)->
    if @equals client.connection.delegate
      oldFetchMounts.call @,callback
    else
      callback new KodingError "access denied for guest."

  oldFetchRepos = @::fetchRepos
  fetchRepos: secure (client,callback)->
    if @equals client.connection.delegate
      oldFetchRepos.call @,callback
    else
      callback new KodingError "access denied for guest."

  oldFetchDatabases = @::fetchDatabases
  fetchDatabases: secure (client,callback)->
    if @equals client.connection.delegate
      oldFetchDatabases.call @,callback
    else
      callback new KodingError "access denied for guest."

  setClientId:(@clientId)->

  getFullName:->
    {firstName, lastName} = @data.profile
    return "#{firstName} #{lastName}"

  fetchStorage$: (name, callback)->

    @fetchStorage { 'data.name' : name }, callback

  fetchStorages$: (whitelist=[], callback)->

    options = if whitelist.length then { 'data.name' : $in : whitelist } else {}

    @fetchStorages options, callback

  store: secure (client, {name, content}, callback)->
    unless @equals client.connection.delegate
      return callback new KodingError "Attempt to access unauthorized storage"

    @_store {name, content}, callback

  unstore: secure (client, name, callback)->

    unless @equals client.connection.delegate
      return callback new KodingError "Attempt to remove unauthorized storage"

    @fetchStorage { 'data.name' : name }, (err, storage)=>
      console.error err, storage  if err
      return callback err  if err
      unless storage
        return callback new KodingError "No such storage"

      storage.remove callback

  _store: ({name, content}, callback)->
    @fetchStorage { 'data.name' : name }, (err, storage)=>
      if err
        return callback new KodingError "Attempt to access storage failed"
      else if storage
        storage.update $set: {content}, (err) -> callback err, storage
      else
        storage = new JStorage {name, content}
        storage.save (err)=>
          return callback err  if err
          rel = new Relationship
            targetId    : storage.getId()
            targetName  : 'JStorage'
            sourceId    : @getId()
            sourceName  : 'JAccount'
            as          : 'storage'
            data        : {name}
          rel.save (err)-> callback err, storage

  fetchAppStorage$: secure (client, options, callback)->
    unless @equals client.connection.delegate
      return callback "Attempt to access unauthorized application storage"

    {appId, version} = options
    @fetchAppStorage {'data.appId':appId, 'data.version':version}, (err, storage)=>
      if err then callback err
      else unless storage?
        # log.info 'Creating new storage:', appId, version, @profile.nickname
        newStorage = new JAppStorage {appId, version}
        newStorage.save (err) =>
          if err then callback err
          else
            # manually add the relationship so that we can
            # query the edge instead of the target C.T.
            rel = new Relationship
              targetId    : newStorage.getId()
              targetName  : 'JAppStorage'
              sourceId    : @getId()
              sourceName  : 'JAccount'
              as          : 'appStorage'
              data        : {appId, version}
            rel.save (err)-> callback err, newStorage
      else
        callback err, storage

  fetchUser:(callback)->
    JUser = require './user'
    selector = { targetId: @getId(), as: 'owner', sourceName: 'JUser' }
    Relationship.one selector, (err, rel) ->
      return callback err   if err
      return callback null  unless rel
      JUser.one {_id: rel.sourceId}, callback

  markAllContentAsLowQuality:->
    # this is obsolete
    @fetchContents (err, contents)->
      contents.forEach (item)->
        item.update {$set: isLowQuality: yes}, ->
          if item.bongo_.constructorName == 'JComment'
            item.flagIsLowQuality ->
              item.emit 'ContentMarkedAsLowQuality', null
          else
            item.emit 'ContentMarkedAsLowQuality', null

  unmarkAllContentAsLowQuality:->
    # this is obsolete
    @fetchContents (err, contents)->
      contents.forEach (item)->
        item.update {$set: isLowQuality: no}, ->
          if item.bongo_.constructorName == 'JComment'
            item.unflagIsLowQuality ->
              item.emit 'ContentUnmarkedAsLowQuality', null
          else
            item.emit 'ContentUnmarkedAsLowQuality', null

  cleanCacheFromActivities:->
    # TODO: this is obsolete
    CActivity.emit 'UserMarkedAsTroll', @getId()

  @taintedAccounts = {}
  @taint =(id)->
    @taintedAccounts[id] = yes

  @untaint =(id)->
    delete @taintedAccounts[id]

  @isTainted =(id)->
    isTainted = @taintedAccounts[id]
    isTainted

  sendNotification:(event, contents)->
    @emit 'notification', {
      routingKey: @profile.nickname
      event, contents
    }

  fetchGroupsWithPending:(method, status, options, callback)->
    [callback, options] = [options, callback]  unless callback
    options ?= {}

    selector    = {}
    if options.groupIds
      selector.sourceId = $in:(ObjectId groupId for groupId in options.groupIds)
      delete options.groupIds

    relOptions = targetOptions: selector: {status}

    @["fetchInvitation#{method}s"] {}, relOptions, (err, rels)->
      return callback err  if err
      JGroup = require './group'
      JGroup.some _id:$in:(rel.sourceId for rel in rels), options, callback

  fetchGroupsWithPendingRequests:(options, callback)->
    @fetchGroupsWithPending 'Request', 'pending', options, callback

  fetchGroupsWithPendingInvitations:(options, callback)->
    @fetchGroupsWithPending '', 'sent', options, callback

  fetchMyGroupInvitationStatus: secure (client, sourceId, callback)->
    return  unless @equals client.connection.delegate

    options = targetOptions: selector: status: 'pending'
    @fetchInvitationRequests {sourceId}, options, (err, requests)=>
      return callback err                if err
      return callback null, 'requested'  if requests?[0]

      options = targetOptions: selector: status: 'sent'
      @fetchInvitations {sourceId}, options, (err, invites)=>
        return callback err              if err
        return callback null, 'invited'  if invites?[0]
        return callback null, no

  cancelRequest: secure (client, group, callback)->
    options = targetOptions: selector: status: 'pending'
    @fetchInvitationRequests {sourceId: group._id}, options, (err, [request])->
      return callback err                                  if err
      return callback 'could not find invitation request'  unless request
      request.remove callback

  fetchInvitationByGroup:(group, callback)->
    options = targetOptions: selector: {status: 'sent', group: group.slug}
    @fetchInvitations {}, options, (err, [invite])->
      return callback err                          if err
      return callback 'could not find invitation'  unless invite

      JGroup = require './group'
      JGroup.one _id: group._id, (err, groupObj)->
        return callback err  if err
        callback null, invite, groupObj

  acceptInvitation: secure (client, group, callback)->
    @fetchInvitationByGroup group, (err, invite, groupObj)=>
      return callback err  if err
      groupObj.approveMember this, (err)->
        return callback err  if err
        invite.update $set:status:'accepted', callback

  ignoreInvitation: secure (client, group, callback)->
    @fetchInvitationByGroup group, (err, invite)->
      return callback err  if err
      invite.update $set:status:'ignored', callback

  @byRelevance$ = permit 'list members',
    success: (client, seed, options, callback)->
      @byRelevance client, seed, options, callback

  fetchMyPermissions: secure (client, callback)->
    @fetchMyPermissionsAndRoles client, (err, permissions, roles)->
      callback err, permissions

  fetchMyPermissionsAndRoles: secure (client, callback)->
    JGroup = require './group'

    slug = client.context.group ? 'koding'
    JGroup.one {slug}, (err, group)=>
      return callback err  if err
      group.fetchPermissionSet (err, permissionSet)=>
        return callback err  if err
        cb = (err, roles)=>
          return callback err  if err
          perms = (perm.permissions.slice()\
                  for perm in permissionSet.permissions\
                  when perm.role in roles)
          {flatten} = require 'underscore'
          callback null, flatten(perms), roles

        if this instanceof JAccount
          group.fetchMyRoles client, cb
        else
          cb null, ['guest']

  oldAddTags = @::addTags
  addTags: secure (client, tags, options, callback)->
    client.context.group = 'koding'
    oldAddTags.call this, client, tags, options, callback

  fetchUserDomains: (callback) ->
    JDomain = require './domain'

    Relationship.some
      targetName: "JDomain"
      sourceId  : @getId()
      sourceName: "JAccount"
    ,
      targetId : 1
    , (err, rels)->
      return callback err if err

      JDomain.some {_id: $in: (rel.targetId for rel in rels)}, {}, (err, domains)->
        domainList = []
        unless err
          # we don't allow users to work on domains such as
          # shared-x/vm-x.groupSlug.kd.io or x.koding.kd.io
          # so we are filtering them here.
          domainList = domains.filter (domain)->
            domainName = domain.domain
            !(/^shared|vm[\-]?([0-9]+)?/.test domainName) and \
            !(/(.*)\.(koding|guests)\.kd\.io$/.test domainName)

        callback err, domainList

  fetchDomains$: permit
    advanced: [
      { permission: 'list own domains', validateWith: Validators.own }
    ]
    success: (client, callback) ->
      @fetchUserDomains callback


  {Member, OAuth} = require "./graph"

  fetchMyFollowingsFromGraph: secure (client, options, callback)->
    options.client = client
    Member.fetchFollowingMembers options, (err, results)=>
      if err then return callback err
      else return callback null, results

  fetchMyFollowersFromGraph: secure (client, options, callback)->
    options.client = client
    Member.fetchFollowerMembers options, (err, results)=>
      if err then return callback err
      else return callback null, results

  ## NEWER IMPLEMENATION: Fetch ids from graph db, get items from document db.
  fetchRelatedTagsFromGraph: secure (client, options, callback)->
    @delegateToGraph client, "fetchRelatedTagsFromGraph", options, callback

  fetchRelatedUsersFromGraph: secure (client, options, callback)->
    @delegateToGraph client, "fetchRelatedUsersFromGraph", options, callback

  delegateToGraph:(client, methodName, options, callback)->
    options.userId = client.connection.delegate._id
    OAuth[methodName] options, callback


  ## NEWER IMPLEMENATION: Fetch ids from graph db, get items from document db.

  sendEmailVMTurnOnFailureToSysAdmin: secure (client, vmName, reason)->
    time = (new Date).toJSON()
    JMail = require './email'
    JUser = require './user'
    JUser.one username:client.context.user, (err, user)->
      emailAddr = if user then user.email else ''
      email     = new JMail
        from    : 'hello@koding.com'
        email   : 'sysops@koding.com'
        replyto : emailAddr
        subject : "'#{vmName}' vm turn on failed for user '#{client.context.user}'"
        content : "Reason: #{reason}"
        force   : yes
      email.save ->

  unlinkOauth: secure (client, provider, callback)->
    {delegate} = client.connection
    isMine     = @equals delegate
    if isMine
      @fetchUser (err, user)=>
        return callback err  if err

        query                            = {}
        query["foreignAuth.#{provider}"] = ""
        user.update $unset: query, (err)=>
          return callback err  if err
          @oauthDeleteCallback provider, user, callback
    else
      callback new KodingError 'Access denied'

  oauthDeleteCallback: (provider, user, callback)->
    if provider is "google"
      user.fetchAccount 'koding', (err, account)->
        return callback err  if err
        JReferrableEmail = require "./referrableemail"
        JReferrableEmail.delete user.username, callback
    else
      callback()

  # we are using this in sorting members list..
  updateMetaModifiedAt: (callback)->
    @update $set: 'meta.modifiedAt': new Date, callback
