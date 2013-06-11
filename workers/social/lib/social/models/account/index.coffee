jraphical = require 'jraphical'

KodingError = require '../../error'

likeableActivities = ['JCodeSnip', 'JStatusUpdate', 'JDiscussion',
                      'JOpinion', 'JCodeShare', 'JLink', 'JTutorial',
                      'JBlogPost'
                     ]

{sharedStaticMethods, sharedInstanceMethods} = require '../account/methods'

module.exports = class JAccount extends jraphical.Module
  log4js          = require "log4js"
  log             = log4js.getLogger("[JAccount]")

  @trait __dirname, '../../traits/followable'
  @trait __dirname, '../../traits/filterable'
  @trait __dirname, '../../traits/taggable'
  @trait __dirname, '../../traits/notifying'
  @trait __dirname, '../../traits/flaggable'

  JAppStorage = require '../appstorage'
  JTag = require '../tag'
  CActivity = require '../activity'

  @getFlagRole = 'content'

  {ObjectId, Register, secure, race, dash, daisy} = require 'bongo'
  {Relationship} = jraphical
  {permit} = require '../group/permissionset'

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
    sharedEvents    :
      static        : [
        { name: 'AccountAuthenticated' } # TODO: we need to handle this event differently.
      ]
      instance      : [
        { name: 'updateInstance' }
      ]
    sharedMethods :
      static      : sharedStaticMethods()
      instance    : sharedInstanceMethods()
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
      profile               :
        about               : String
        nickname            :
          type              : String
          validate          : require('../name').validateName
          set               : (value)-> value.toLowerCase()
        hash                :
          type              : String
          # email             : yes
        ircNickname         : String
        firstName           :
          type              : String
          required          : yes
        lastName            :
          type              : String
          default           : ''
        description         : String
        handles             :
          twitter           : String
          github            : String
        staticPage          :
          show              :
            type            : Boolean
            default         : yes
          showTypes         : [String]
          title             : String
          about             : String
          # backgrounds       : [String]
          customize         :
            background       :
              customImages    : [String]
              customType      :
                type          : String
                default       : 'defaultImage'
                enum          : ['invalid type', [ 'defaultImage', 'customImage', 'defaultColor', 'customColor']]
              customValue     :
                type          : String
                default       : '1'
              customOptions   : Object
        avatar              : String
        status              : String
        experience          : String
        experiencePoints    :
          type              : Number
          default           : 0
        lastStatusUpdate    : String
      globalFlags           : [String]
      meta                  : require 'bongo/bundles/meta'
      onlineStatus          :
        type                : String
        enum                : ['invalid status',['online','offline','away','busy']]
        default             : 'online'

    relationships           : ->
      JPrivateMessage = require '../messages/privatemessage'

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

      limit:
        as          : 'invite'
        targetType  : "JLimit"

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

  constructor:->
    super
    @notifyOriginWhen 'PrivateMessageSent', 'FollowHappened'

  checkPermission: (target, permission, callback)->
    JPermissionSet = require '../group/permissionset'
    client =
      context     : { group: target.slug }
      connection  : { delegate: this }
    advanced =
      if Array.isArray permission then permission
      else JPermissionSet.wrapPermission permission
    JPermissionSet.checkPermission client, advanced, target, callback

  setBackgroundImage: secure (client, type, value, callback=->)->
    {delegate}    = client.connection
    isMine        = this.equals delegate
    if isMine
      if type is 'customImage'
        operation =
          $set: {}
          $addToSet : {}
        operation.$addToSet['profile.staticPage.customize.background.customImages'] = value
      else
        operation = $set : {}

      operation.$set["profile.staticPage.customize.background.customType"] = type

      if type in ['defaultImage','defaultColor','customColor','customImage']
        operation.$set["profile.staticPage.customize.background.customValue"] = value


      @update operation, callback

  setAbout: secure (client, text, callback)->
    {delegate}    = client.connection
    isMine        = this.equals delegate
    if isMine
      @fetchAbout (err, about)=>
        console.log err if err
        unless about
          JMarkdownDoc = require '../markdowndoc'
          about = new JMarkdownDoc content: text

          daisy queue = [
            ->
              about.save (err)->
                console.log err
                if err then callback err
                else queue.next()
            =>
              @addAbout about, (err)->
                console.log err
                if err then callback err
                else queue.next()
            ->
              callback null, about
          ]

        else
          about.update $set:{ content: text }, (err)=>
            if err then callback err
            else callback null, about


  @renderHomepage: require './render-homepage'

  fetchHomepageView:(callback)->

    callback null, JAccount.renderHomepage
      profile       : @profile
      account       : this
      counts        : @counts
      skillTags     : @skillTags

  setHandle: secure (client, data, callback)->
    {delegate}    = client.connection
    {service,value} = data
    selector = "profile.handles."+service
    isMine        = this.equals delegate
    if isMine and service in ['twitter','github']
      value = null if value is ''
      operation = $set: {}
      operation.$set[selector] = value
      @update operation, callback
    else
      callback? new KodingError 'Access denied!'

  setStaticPageTitle: secure (client, title, callback)->
    {delegate}    = client.connection
    selector      = "profile.staticPage.title"
    isMine        = this.equals delegate
    if isMine
      operation = $set: {}
      operation.$set[selector] = title
      @update operation, callback
    else
      callback? new KodingError 'Access denied!'

  setStaticPageAbout: secure (client, about, callback)->
    {delegate}    = client.connection
    selector      = "profile.staticPage.about"
    isMine        = this.equals delegate
    if isMine
      operation = $set: {}
      operation.$set[selector] = about
      @update operation, callback
    else
      callback? new KodingError 'Access denied!'


  addStaticPageType: secure (client, type, callback)->
    {delegate}    = client.connection
    isMine        = this.equals delegate
    if isMine
      @update {$addToSet: 'profile.staticPage.showTypes': type}, callback
    else
      callback? new KodingError 'Access denied!'

  # addStaticBackground: secure (client, url, callback)->
  #   {delegate}    = client.connection
  #   isMine        = this.equals delegate
  #   if isMine
  #     @update {$addToSet: 'profile.staticPage.backgrounds': url}, callback
  #   else
  #     callback? new KodingError 'Access denied!'

  removeStaticPageType: secure (client, type, callback)->
    {delegate}    = client.connection
    isMine        = this.equals delegate
    if isMine
      @update {$pullAll: 'profile.staticPage.showTypes': [type]}, callback
    else
      callback? new KodingError 'Access denied!'


  setStaticPageVisibility: secure (client, visible=yes, callback)->
    {delegate}    = client.connection
    isMine        = this.equals delegate
    if isMine
      @update ($set: 'profile.staticPage.show': visible), callback
    else
      callback? new KodingError 'Access denied!'


  fetchGroups: secure (client, callback)->
    JGroup        = require '../group'
    {groupBy}     = require 'underscore'
    {delegate}    = client.connection
    isMine        = this.equals delegate
    edgeSelector  =
      sourceName  : 'JGroup'
      targetId    : @getId()
      as          : 'member'
    edgeFields    =
      sourceId    : 1
      as          : 1
    edgeOptions   =
      sort        : { timestamp: -1 }
      limit       : 10
    Relationship.someData edgeSelector, edgeFields, edgeOptions, (err, cursor)->
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
    JGroup = require '../group'
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
      callback new KodingError 'Access denied!'
    else
      JSession = require '../session'
      JSession.update {clientId: sessionToken}, $set:{username: nickname}, callback

  @reserveNames =(options, callback)->
    [callback, options] = [options, callback]  unless callback
    options ?= {}
    options.limit ?= 100
    options.skip ?= 0
    JName = require '../name'
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
    JUser = require '../user'
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
      callback new KodingError 'Access denied.'
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

  fetchNonces: secure (client, callback)->
    {delegate} = client.connection
    unless @equals delegate
      callback new KodingError 'Access denied.'
    else
      client.connection.remote.fetchClientId (clientId)->
        JSession.one {clientId}, (err, session)->
          if err
            callback err
          else
            nonces = (hat() for i in [0...10])
            session.update $addToSet: nonces: $each: nonces, (err)->
              if err
                callback err
              else
                callback null, nonces

  fetchKiteChannelId: secure (client, kiteName, callback)->
    {delegate} = client.connection
    unless delegate instanceof JAccount
      callback new KodingError 'Access denied.'
    else
      callback null, "private-#{kiteName}-#{delegate.profile.nickname}"

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

    # Like count
    Relationship.count
      as         : 'like'
      targetId   : @getId()
      sourceName : $in: likeableActivities
    , (err, count)=>
      @update ($set: 'counts.likes': count), ->

    # Member Following count
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

  dummyAdmins = [ "sinan", "devrim", "aleksey-m", "gokmen", "chris",
                  "arvidkahl", "testdude", "blum", "neelance", "halk",
                  "fatihacet", "chrisblum" ]

  flagAccount: secure (client, flag, callback)->
    {delegate} = client.connection
    JAccount.taint @getId()
    if delegate.can 'flag', this
      @update {$addToSet: globalFlags: flag}, callback
      if flag is 'exempt'
        console.log 'is exempt'
        @markAllContentAsLowQuality()
        @cleanCacheFromActivities()
      else
        console.log 'aint exempt'
    else
      callback new KodingError 'Access denied'

  unflagAccount: secure (client, flag, callback)->
    {delegate} = client.connection
    JAccount.taint @getId()
    if delegate.can 'flag', this
      @update {$pullAll: globalFlags: [flag]}, callback
      if flag is 'exempt'
        console.log 'was exempt'
        @unmarkAllContentAsLowQuality()
      else
        console.log 'aint exempt'
    else
      callback new KodingError 'Access denied'

  updateFlags: secure (client, flags, callback)->
    {delegate} = client.connection
    JAccount.taint @getId()
    if delegate.can 'flag', this
      @update {$set: globalFlags: flags}, callback
    else
      callback new KodingError 'Access denied'

  checkFlag:(flagToCheck)->
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
           'administer url aliases', 'migrate-kodingen-users', \
           'administer accounts', 'grant-invites', 'send-invites', \
           'migrate-koding-users'
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
        jraphical.Relationship.all
          targetName  : 'JPrivateMessage',
          targetId    : message.getId(),
          sourceId    :
            $ne       : delegate.getId()
        , (err, rels)->
          if err
            callback err
          else unless rels?.length
            message.participants = []
          else
            # only include unique participants.
            message.participants = (rel for rel in rels when register.sign rel.sourceId)
          fin()
      , callback
      fetchParticipants(message) for message in messages when message?

    secure ({connection}, options, callback)->
      [callback, options] = [options, callback] unless callback
      unless @equals connection.delegate
        callback new KodingError 'Access denied.'
      else
        options or= {}
        selector =
          if options.as
            as: options.as
          else
            {}
        # options.limit     = 8
        options.fetchMail = yes
        @fetchPrivateMessages selector, options, (err, messages)->
          if err
            callback err
          else
            callback null, [] if messages.length is 0
            collectParticipants messages, connection.delegate, (err)->
              if err
                callback err
              else
                callback null, messages

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
      callback new KodingError 'Access denied.'
    else
      @fetchActivities selector, options, @constructor.collectTeasersAllCallback callback

  fetchActivityTeasers : secure ({connection}, selector, options, callback)->
    unless @equals connection.delegate
      callback new KodingError 'Access denied.'
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
    {profile} = @data
    profile.firstName+' '+profile.lastName

  fetchStorage: secure (client, options, callback)->
    unless @equals client.connection.delegate
      return callback "Attempt to access unauthorized application storage"

    {appId, version} = options
    @fetchAppStorage {'data.appId':appId, 'data.version':version}, (err, storage)=>
      if err then callback err
      else unless storage?
        log.info 'creating new storage for application', appId, version
        newStorage = new JAppStorage {appId, version}
        newStorage.save (err) =>
          if err then callback error
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
    JUser = require '../user'
    JUser.one {username: @profile.nickname}, callback

  markAllContentAsLowQuality:->
    @fetchContents (err, contents)->
      contents.forEach (item)->
        item.update {$set: isLowQuality: yes}, ->
          if item.bongo_.constructorName == 'JComment'
            item.flagIsLowQuality ->
              item.emit 'ContentMarkedAsLowQuality', null
          else
            item.emit 'ContentMarkedAsLowQuality', null

  unmarkAllContentAsLowQuality:->
    @fetchContents (err, contents)->
      contents.forEach (item)->
        item.update {$set: isLowQuality: no}, ->
          if item.bongo_.constructorName == 'JComment'
            item.unflagIsLowQuality ->
              item.emit 'ContentUnmarkedAsLowQuality', null
          else
            item.emit 'ContentUnmarkedAsLowQuality', null

  cleanCacheFromActivities:->
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
  getInvitiationRequestRelationships:(options, status, callback)->
    JInvitationRequest = require '../invitationrequest'

    @fetchUser (err, user)=>
      return callback err if err

      selector =
        $or: [
          {'koding.username': @profile.nickname,}
          {email: user.email}
        ]
        status: status

      JInvitationRequest.some selector, {}, (err, requests)->
        return callback err if err
        return callback null, [] unless requests

        selector =
          targetName : 'JInvitationRequest'
          targetId   : $in:(request.getId() for request in requests)
          sourceName : 'JGroup'

        if options?.groupIds
          selector.sourceId = $in:(ObjectId groupId for groupId in options.groupIds)
          delete options.groupIds

        Relationship.some selector, {}, callback

  fetchPendingGroupRequests:(options, callback)->
    JGroup = require '../group'

    @getInvitiationRequestRelationships options, 'pending', (err, rels)->
      return callback err if err
      JGroup.some _id:$in:(rel.sourceId for rel in rels), options, callback

  fetchPendingGroupInvitations:(options, callback)->
    [callback, options] = [options, callback]  unless callback
    JGroup = require '../group'

    @getInvitiationRequestRelationships options, 'sent', (err, rels)->
      return callback err if err
      JGroup.some _id:$in:(rel.sourceId for rel in rels), options, callback

  getInvitationRequestByGroup: secure (client, groupData, status, callback)->
    return unless @equals client.connection.delegate

    JInvitationRequest = require '../invitationrequest'
    JGroup             = require '../group'

    JGroup.one _id:groupData._id, (err, group)=>
      return callback err if err
      @fetchUser (err, user)=>
        return callback err if err
        options =
          targetOptions:
            selector:
              $or: [
                {'koding.username': @profile.nickname}
                {email: user.email}
              ]
              status: status
          options:
            sort: { timestamp: -1 }

        group.fetchInvitationRequests {}, options, callback

  cancelRequest: secure (client, group, callback)->
    @getInvitationRequestByGroup client, group, 'pending', (err, [request])->
      return callback err if err or not request
      request.remove callback

  acceptInvitation: secure (client, group, callback)->
    @getInvitationRequestByGroup client, group, 'sent', (err, [request])->
      return callback err if err or not request
      request.acceptInvitationByInvitee client, callback

  ignoreInvitation: secure (client, group, callback)->
    @getInvitationRequestByGroup client, group, 'sent', (err, [request])->
      return callback err if err or not request
      request.ignoreInvitationByInvitee client, callback
  # koding.pre 'methodIsInvoked', (client, callback)=>
  #   delegate = client?.connection?.delegate
  #   id = delegate?.getId()
  #   unless id
  #     callback client
  #   else if @isTainted id
  #     JAccount.one _id: id, (err, account)=>
  #       if err
  #         console.log 'there was an error'
  #       else
  #         @untaint id
  #         client.connection.delegate = account
  #         console.log 'delegate is force-loaded from db'
  #         callback client
  #   else
  #     callback client

  fetchFollowersFromNeo4j:(options={}, callback)->
      # returns accounts that follow this account
      query =
        """
        start  koding=node:koding(id='#{@getId()}')
        MATCH koding-[:follower]->followers
        where followers.name="JAccount
        return followers
        """

      options['resultsKey'] = 'followers'
      Graph          = require "../graph/graph"
      graph = new Graph(config:KONFIG['neo4j'])
      graph.fetchFromNeo4j(query, options, callback)

  @byRelevance$ = permit 'list members',
    success: (client, seed, options, callback)->
      @byRelevance client, seed, options, callback

  fetchMyPermissions: secure (client, callback)->
    @fetchMyPermissionsAndRoles client, (err, permissions, roles)->
      callback err, permissions

  fetchMyPermissionsAndRoles: secure (client, callback)->
    JGroup = require '../group'

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
