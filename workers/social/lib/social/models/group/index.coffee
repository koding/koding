KONFIG         = require 'koding-config-manager'
async          = require 'async'
{ Module }     = require 'jraphical'
{ difference } = require 'underscore'


module.exports = class JGroup extends Module

  [ERROR_UNKNOWN, ERROR_NO_POLICY, ERROR_POLICY] = [403010, 403001, 403009]

  { Relationship } = require 'jraphical'

  { Inflector, ObjectId, ObjectRef, secure, signature } = require 'bongo'

  JPermissionSet = require './permissionset'
  { permit }     = JPermissionSet

  JAccount       = require '../account'
  KodingError    = require '../../error'
  Validators     = require './validators'
  async          = require 'async'
  { throttle, extend }     = require 'underscore'

  PERMISSION_EDIT_GROUPS = [
    { permission: 'edit groups',     superadmin: yes }
    { permission: 'edit own groups', validateWith: Validators.group.admin }
  ]

  @API_TOKEN_LIMIT = 5

  @trait __dirname, '../../traits/filterable'
  @trait __dirname, '../../traits/followable'
  @trait __dirname, '../../traits/taggable'
  @trait __dirname, '../../traits/protected'
  @trait __dirname, '../../traits/joinable'
  @trait __dirname, '../../traits/slugifiable'
  @trait __dirname, '../../traits/notifying'
  @trait __dirname, '../../traits/notifiable'

  @share()

  @set
    softDelete      : yes
    slugifyFrom     : 'slug'
    slugTemplate    : '#{slug}'
    feedable        : no
    memberRoles     : ['admin', 'moderator', 'member', 'guest']
    permissions     :
      'grant permissions'                 : []
      'open group'                        : ['member', 'moderator']
      'list members'                      : ['moderator', 'member']
      'read group activity'               :
        public                            : ['guest', 'member', 'moderator']
        private                           : ['member', 'moderator']
      'create groups'                     : ['moderator']
      'edit groups'                       : ['moderator']
      'edit own groups'                   : ['member', 'moderator']
      'query collection'                  : ['member', 'moderator']
      'update collection'                 : ['moderator']
      'assure collection'                 : ['moderator']
      'remove documents from collection'  : ['moderator']
      'view readme'                       : ['member', 'moderator']
      'send invitations'                  : ['moderator']

      # those are for messages
      'read posts'              : ['member', 'moderator']
      'create posts'            : ['member', 'moderator']
      'edit posts'              : ['moderator']
      'delete posts'            : ['moderator']
      'edit own posts'          : ['member', 'moderator']
      'delete own posts'        : ['member', 'moderator']
      'reply to posts'          : ['member', 'moderator']
      'like posts'              : ['member', 'moderator']
      'pin posts'               : ['member', 'moderator']
      'send private message'    : ['member', 'moderator']
      'list private messages'   : ['member', 'moderator']
      'delete own channel'      : ['member']
      'delete channel'          : ['member', 'moderator']

      # JTag related permissions
      'read tags'               : ['member', 'moderator']
      'create tags'             : ['member', 'moderator']
      'freetag content'         : ['member', 'moderator']
      'browse content by tag'   : ['member', 'moderator']
      'edit tags'               : ['moderator']
      'delete tags'             : ['moderator']
      'edit own tags'           : ['moderator']
      'delete own tags'         : ['moderator']
      'assign system tag'       : ['moderator']
      'fetch system tag'        : ['moderator']
      'create system tag'       : ['moderator']
      'remove system tag'       : ['moderator']
      'create synonym tags'     : ['moderator']
    indexes         :
      slug          : 'unique'
    sharedEvents    :
      static        : []
      instance      : []
    sharedMethods   :
      static        :
        one:
          (signature Object, Function)
        create:
          (signature Object, Function)
        each: [
          (signature Object, Object, Function)
          (signature Object, Object, Object, Function)
        ]
        count: [
          (signature Function)
          (signature Object, Function)
        ]
        byRelevance:[
          (signature String, Function)
          (signature String, Object, Function)
        ]
        someWithRelationship:
          (signature Object, Object, Function)
        fetchMyMemberships: [
          (signature [ObjectId], Function)
          (signature [ObjectId], String, Function)
        ]
        suggestUniqueSlug: [
          (signature String, Function)
          (signature String, Number, Function)
        ]
      instance      :
        join: [
          (signature Function)
          (signature Object, Function)
        ]
        leave:[
          (signature Function)
          (signature Object, Function)
        ]
        modify:
          (signature Object, Function)
        fetchPermissions: [
          (signature Function)
          (signature Object, Function)
        ]
        updatePermissions:
          (signature Object, Function)
        fetchAdmins: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        fetchAdminsWithEmail: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        fetchModerators: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        fetchModeratorsWithEmail: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        fetchMembers: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        fetchMembersWithEmail: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        fetchBlockedAccounts: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        fetchBlockedAccountsWithEmail: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        fetchResources: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        searchMembers: [
          (signature String, Object, Function)
        ]
        fetchRoles: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        fetchMyRoles:
          (signature Function)
        fetchUserRoles: [
          (signature Function)
          (signature [String], Function)
        ]
        changeMemberRoles:
          (signature String, [String], Function)
        canOpenGroup:
          (signature Function)
        canEditGroup:
          (signature Function)
        fetchMembershipPolicy:
          (signature Function)
        modifyMembershipPolicy:
          (signature Object, Function)
        isMember:
          (signature Object, Function)
        kickMember:
          (signature String, Function)
        unblockMember: [
          (signature String, Function)
          (signature Object, Function)
        ]
        transferOwnership:
          (signature String, Function)
        destroy:
          (signature Function)
        addSubscription:
          (signature String, Function)
        fetchSubscription:
          (signature Function)
        fetchPermissionSetOrDefault:
          (signature Function)
        fetchUserStatus:
          (signature Object, Function)
        toggleFeature:
          (signature Object, Function)
        sendNotification:
          (signature String, String, Function)
        setLimit:
          (signature Object, Function)
        fetchApiTokens: [
          (signature Function)
          (signature Object, Function)
        ]
    schema          :
      title         :
        type        : String
        required    : yes

      body          : String
      # channelId for mapping social API
      # to internal usage
      socialApiChannelId             : String
      # channel id for announcements of a group
      socialApiAnnouncementChannelId : String
      # channel id for default of a non-koding group
      socialApiDefaultChannelId : String
      avatar        : String
      slug          :
        type        : String
        validate    : require('../name').validateName
        set         : (value) -> value.toLowerCase()
      privacy       :
        type        : String
        enum        : ['invalid privacy type', [
          'public'
          'private'
        ]]
      visibility    :
        type        : String
        enum        : ['invalid visibility type', [
          'visible'
          'hidden'
        ]]
      # parent        : ObjectRef
      counts        :
        members     : Number
      customize     :
        coverPhoto  : String
        logo        : String
        chatlioId   : String
        default     : -> return {}
      disabledFeatures: Object
      # BEWARE: if anyone needs to put a default value here in stackTemplates field
      # it would break the onboarding process of showing the initial stacks not
      # configured modal, so don't. - SY
      stackTemplates  : [ ObjectId ]
      # DefaultChannels holds the default channels for a group, when a user joins
      # to this group, participants will be automatically added to regarding
      # channels
      # those should be social api channel ids
      defaultChannels : [ String ]
      # allowed domains are used for company domains, if a new register tries to
      # join to a group/team we will check if they have a valid invitation code,
      # then we will check if the domain they are trying to register is an
      # allowed global domain
      allowedDomains  : [ String ]
      # Generic config object for future requirements on groups ~ GG
      config        : Object
      # Api usage can be disabled or enabled for the group
      isApiEnabled : Boolean
      payment      : Object

    broadcastableRelationships : [
      'member', 'moderator', 'admin'
      'owner', 'tag', 'role'
    ]
    relationships : ->
      JAccount    = require '../account'
      JCredential = require '../computeproviders/credential'

      return {
        permissionSet :
          targetType  : JPermissionSet
          as          : 'permset'
        defaultPermissionSet:
          targetType  : JPermissionSet
          as          : 'defaultpermset'
        member        :
          targetType  : JAccount
          as          : 'member'
        moderator     :
          targetType  : JAccount
          as          : 'moderator'
        admin         :
          targetType  : JAccount
          as          : 'admin'
        owner         :
          targetType  : JAccount
          as          : 'owner'
        blockedAccount:
          targetType  : JAccount
          as          : 'blockedAccount'
        subgroup      :
          targetType  : 'JGroup'
          as          : 'parent'
        tag           :
          targetType  : 'JTag'
          as          : 'tag'
        role          :
          targetType  : 'JGroupRole'
          as          : 'role'
        membershipPolicy :
          targetType  : 'JMembershipPolicy'
          as          : 'owner'
        invitation:
          targetType  : 'JInvitation'
          as          : 'owner'
        credential    :
          as          : ['owner', 'user']
          targetType  : JCredential
      }


  constructor: ->
    super

    @on 'MemberAdded', (member) ->
      @constructor.emit 'MemberAdded', { group: this, member }

      return  if @slug is 'guests'

      @prepareNewlyAddedMember member, (err, memberData) =>

        return @sendNotification 'GroupJoined', {}  if err

        username = member.data.profile.nickname
        memberData.username = username
        memberData.id = member.data._id

        @sendNotification 'GroupJoined',
          actionType : 'groupJoined'
          actorType  : 'member'
          subject    : ObjectRef(this).data
          member     : memberData

    @on 'MemberRemoved', (member, requester) ->

      requester ?= member
      @constructor.emit 'MemberRemoved', { group: this, member, requester }

      return  if @slug is 'guests'

      username = member.data.profile.nickname
      member = ObjectRef(member).data
      member.username = username

      @sendNotification 'GroupLeft',
        actionType : 'groupLeft'
        actorType  : 'member'
        subject    : ObjectRef(this).data
        member     : member

  @render        :
    loggedIn     :
      kodingHome : require '../../render/loggedin/kodinghome'
      groupHome  : require '../../render/loggedin/grouphome'
      subPage    : require '../../render/loggedin/subpage'
    loggedOut    :
      groupHome  : require '../../render/loggedout/grouphome'
      kodingHome : require '../../render/loggedout/kodinghome'
      subPage    : require '../../render/loggedout/subpage'


  prepareNewlyAddedMember: (member, callback) ->

    memberData = {}
    @fetchRolesByAccount member, (err, roles = []) ->
      return callback err  if err
      memberData.roles = roles
      member.fetchEmail (err, email) ->
        return callback err  if err and not email
        memberData.email = email
        memberData.username = member.data.profile.nickname
        callback null, memberData


  @create = (client, groupData, owner, callback) ->

    # bongo doesnt set array values as their defaults
    groupData.defaultChannels or= []

    JPermissionSet        = require './permissionset'
    JMembershipPolicy     = require './membershippolicy'
    JSession              = require '../session'
    JName                 = require '../name'

    group                 = new this groupData
    group.privacy         = 'private'
    defaultPermissionSet  = new JPermissionSet {}, { privacy: group.privacy }
    { sessionToken }      = client

    save_ = (label, model, callback) ->
      model.save (err) ->
        return callback err  if err
        console.log "#{label} is saved"
        callback null

    queue = [

      (next) ->
        group.useSlug group.slug, (err, slug) ->
          return next err  if err
          return next new KodingError 'Couldn\'t claim the slug!'  unless slug?

          console.log "created a slug #{slug.slug}"
          group.slug  = slug.slug
          group.slug_ = slug.slug
          next()

      (next) ->
        save_ 'group', group, (err) ->
          return next()  unless err
          JName.release group.slug, ->
            next err

      (next) ->
        selector = { clientId : sessionToken }
        params   = { $set : { groupName : group.slug } }

        JSession.update selector, params, next

      (next) ->
        group.addMember owner, next

      (next) ->
        group.addAdmin owner, next

      (next) ->
        group.addOwner owner, next

      (next) ->
        save_ 'default permission set', defaultPermissionSet, next

      (next) ->
        group.addDefaultPermissionSet defaultPermissionSet, next

      (next) ->
        group.addDefaultRoles next

      (next) ->
        group.createSocialApiChannels client, (err) ->
          console.error err  if err
          console.log 'created socialApiId ids'
          next()

      # Auto credential share mechanism is disabled for teams launch
      # This means we won't share any credential with created teams
      # uncomment to enable it again if needed ~ GG
      #
      # (next) ->
      #   { shareCredentials } = require '../computeproviders/teamutils'
      #   account = client.connection.delegate

      #   shareCredentials { group, account }, (err) ->
      #     console.log 'shared credentials', err
      #     next()

    ]

    if 'private' is group.privacy
      queue.push (next) ->
        group.createMembershipPolicy groupData.requestType, -> next()

    async.series queue, (err) ->
      return callback err  if err
      callback null, group


  @create$ = secure (client, formData, callback) ->
    { delegate } = client.connection

    # subOptions = targetOptions: selector: tags: "custom-plan"
    # delegate.fetchSubscription null, subOptions, (err, subscription) =>
    #   return callback err  if err
    #   return callback new KodingError "Subscription is not found"  unless subscription
    #   subscription.debitPack tag: "group", (err) =>
    #     return callback err  if err
    @create client, formData, delegate, (err, group) ->
      return callback err if err
      # group.addSubscription subscription, (err) ->
      #   return callback err  if err
      callback null, { group }

  @findSuggestions = (client, seed, options, callback) ->
    { limit, blacklist, skip }  = options

    @some
      title      : seed
      _id        :
        $nin     : blacklist
      visibility : 'visible'
    ,
      skip
      limit
      sort       : { 'title' : 1 }
    , callback

  # currently groups in a group show global groups, so it does not
  # make sense to allow this method based on current group's permissions
  @byRelevance$ = secure (client, seed, options, callback) ->
    @byRelevance client, seed, options, callback

  @fetchSecretChannelName = (groupSlug, callback) ->
    JName = require '../name'
    JName.fetchSecretName groupSlug, (err, secretName, oldSecretName) ->
      if err then callback err
      else callback null, "group.secret.#{secretName}",
        if oldSecretName then "group.secret.#{oldSecretName}"


  fetchData: (callback) ->

    slug = @getAt 'slug'

    JGroupData = require './groupdata'
    JGroupData.one { slug }, (err, data) ->
      return callback err  if err

      if not data
        data = new JGroupData { slug }
        data.save (err) ->
          return callback err  if err
          callback null, data
      else
        callback null, data


  fetchDataAt: (path, callback) ->

    @fetchData (err, data) ->

      return callback err  if err

      path = "data.#{path}"  if path.indexOf 'data' isnt 0
      callback null, data.getAt path



  sendNotification: (event, contents, callback) ->

    message = {
      groupName  : @slug
      eventName  : event
      body       :
        event    : event
        context  : @slug
        contents : contents
    }

    socialapi = require '../socialapi/requests'
    socialapi.dispatchEvent 'dispatcher_notify_group', message, (err) ->
      console.error '[dispatchEvent][notify_group]', err  if err
      callback? err # do not cause trailing parameters


  sendNotification$: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success: (client, event, contents, callback) ->
      @sendNotification event, contents, callback


  @someWithRelationship$ = permit
    advanced : [{ permission: 'edit groups', superadmin: yes }]
    success  : (client, query, options, callback) ->
      @someWithRelationship client, query, options, callback


  broadcast:(message, event) ->
    @constructor.broadcast @slug, message, event

  changeMemberRoles: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success:(client, targetId, roles, callback) ->
      remove = []
      revokedRoles = []
      sourceId = @getId()
      roles.push 'member'  unless 'member' in roles
      Relationship.some { targetId, sourceId }, {}, (err, rels) =>
        return callback err  if err

        for rel in rels
          if rel.as in roles then roles.splice roles.indexOf(rel.as), 1
          else
            remove.push rel._id
            revokedRoles.push rel.as

        queue = [

          (next) =>
            @countAdmins (err, count) ->
              return next err  if err
              return next()    if count > 1 # this means we have more than one admin account

              # get the diff between revokedRoles and roles, because revoked
              # roles should not have admin role in this case
              diff = difference revokedRoles, roles

              # check if the diff has admin role
              if diff.indexOf('admin') > -1
                errCode    = 'UserIsTheOnlyAdmin'
                errMessage = 'There should be at least one admin to make this change.'
                return next new KodingError errMessage, errCode
              next()

        ]

        # create new roles
        queue = queue.concat roles.map (role) -> (next) ->
          (new Relationship
            targetName  : 'JAccount'
            targetId    : targetId
            sourceName  : 'JGroup'
            sourceId    : sourceId
            as          : role
          ).save next

        # remove existing ones
        queue = queue.concat [

          (next) ->
            if remove.length > 0
              Relationship.remove { _id: { $in: remove } }, next
            else
              next()

          (next) ->
            notifyAccountOnRoleChange client, targetId, roles, next

        ]

        async.series queue, callback

  notifyAccountOnRoleChange = (client, id, roles, callback) ->
    JAccount.one { _id: id }, (err, account) ->
      return callback err  if err or not account

      role = if roles?.length > 0 then roles[0] else 'member'
      contents = { role, group: client.context.group, adminNick: client.connection.delegate.profile.nickname }
      account.sendNotification 'MembershipRoleChanged', contents
      callback null


  addDefaultRoles:(callback) ->
    group = this
    JGroupRole = require './role'
    JGroupRole.all { isDefault: yes }, (err, roles) ->
      if err then callback err
      else
        queue = roles.map (role) -> (fin) ->
          group.addRole role, fin
        async.parallel queue, -> callback()

  # isInAllowedDomain checks if given email's domain is in allowed domains
  isInAllowedDomain: (email) ->
    # allow for all domains for koding
    return yes if @slug is 'koding'

    return no  unless @allowedDomains?.length > 0

    return yes if '*' in @allowedDomains

    # even if incoming email doesnt have a @ in it, whole string will be taken
    # into consideration as domain name
    domain = email.substring email.indexOf('@') + 1 # get the part after @

    return domain in @allowedDomains

  updatePermissions: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success:(client, permissions, callback = -> ) ->
      @fetchPermissionSet (err, permissionSet) =>
        return callback err if err
        if permissionSet
          permissionSet.update { $set:{ permissions } }, callback
        else
          permissionSet = new JPermissionSet { permissions, isCustom: true }
          permissionSet.save (err) =>
            return callback err if err
            @addPermissionSet permissionSet, (err) ->
              return callback err if err
              console.log 'permissionSet is added'
              callback null

  fetchPermissions:do ->
    fixDefaultPermissions_ = (model, permissionSet, callback) ->
      # It was lately recognized that we needed to have a default permission
      # set that is created at the time of group creation, because other
      # permissions may be roled out over time, and it is best to be secure by
      # default.  Without knowing which permissions were present at the time
      # of group creation, we may inadvertantly expose dangerous permissions
      # to underprivileged roles.  We will create this group's "default
      # permissions" by cloning the group's current permission set. C.T.
      defaultPermissionSet = permissionSet.clone()
      defaultPermissionSet.save (err) ->
        if err then callback err
        else model.addDefaultPermissionSet defaultPermissionSet, (err) ->
          if err then callback err
          else callback null, defaultPermissionSet

    fetchPermissions = permit
      advanced: [
        { permission: 'grant permissions' }
        { permission: 'grant permissions', superadmin: yes }
      ]
      success:(client, callback) ->
        { permissionsByModule } = require '../../traits/protected'
        { delegate }            = client.connection
        permissionSet         = null
        defaultPermissionSet  = null

        queue = [

          (next) =>
            @fetchPermissionSet (err, model) ->
              return next err  if err
              permissionSet = model
              next()

          (next) =>
            @fetchDefaultPermissionSet (err, model) =>
              return next err  if err

              if model?
                console.log 'already had defaults'
                defaultPermissionSet = model
                permissionSet = model unless permissionSet
                next()
              else
                console.log 'needed defaults fixed'
                fixDefaultPermissions_ this, permissionSet, (err, newModel) ->
                  defaultPermissionSet = newModel
                  next()

        ]

        async.series queue, (err) ->
          return callback err  if err
          callback null, {
            permissionsByModule
            permissions         : permissionSet.permissions
            defaultPermissions  : defaultPermissionSet.permissions
          }

  fetchRolesByAccount: (account, callback) ->

    return callback new KodingError 'Account not found'  unless account

    Relationship.someData {
      targetId: account.getId()
      sourceId: @getId()
    }
    , { as:1 }
    , (err, cursor) ->
      return callback err  if err

      cursor.toArray (err, arr) ->
        return callback err  if err

        roles = if arr?.length > 0 then (doc.as for doc in arr) else ['guest']
        callback null, roles


  fetchMyRoles: secure (client, callback) ->
    @fetchRolesByAccount client.connection.delegate, callback

  fetchUserRoles: permit
    advanced: [
      { permission: 'list members' }
      { permission: 'list members', superadmin: yes }
    ]
    success:(client, ids, callback) ->
      [callback, ids] = [ids, callback]  unless callback
      @fetchRoles (err, roles) =>
        roleTitles = (role.title for role in roles)
        selector = {
          targetName  : 'JAccount'
          sourceId    : @getId()
          as          : { $in: roleTitles }
        }
        selector.targetId = { $in: ids }  if ids
        Relationship.someData selector, { as:1, targetId:1 }, (err, cursor) ->
          if err then callback err
          else
            cursor.toArray (err, arr) ->
              if err then callback err
              else callback null, arr

  fetchUserStatus: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success:(client, nicknames, callback) ->
      JUser    = require '../user'
      JUser.someData { username: { $in: nicknames } }, { status:1, username:1 }, (err, cursor) ->
        return callback err  if err
        cursor.toArray callback

  fetchMembers$: permit
    advanced: [
      { permission: 'list members' }
      { permission: 'list members', superadmin: yes }
    ]
    success:(client, rest...) ->
      @baseFetcherOfGroupStaff {
        method : @fetchMembers
        client
        rest
      }

  fetchMembersWithEmail: (client, rest...) ->
    @baseFetcherOfGroupStaff {
      method      : @fetchMembers
      fetchEmail  : yes
      client
      rest
    }

  fetchMembersWithEmail$: permit
    advanced: [
      { permission: 'list members' }
      { permission: 'list members', superadmin: yes }
    ]
    success:(client, rest...) ->
      @fetchMembersWithEmail client, rest...

  fetchAdmins$: permit
    advanced: [
      { permission: 'list members' }
      { permission: 'list members', superadmin: yes }
    ]
    success:(client, rest...) ->
      @baseFetcherOfGroupStaff {
        method: @fetchAdmins
        client
        rest
      }

  fetchAdminsWithEmail$: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success:(client, rest...) ->
      @baseFetcherOfGroupStaff {
        method      : @fetchAdmins
        fetchEmail  : yes
        client
        rest
      }

  fetchModerators$: permit
    advanced: [
      { permission: 'list members' }
      { permission: 'list members', superadmin: yes }
    ]
    success:(client, rest...) ->
      @baseFetcherOfGroupStaff {
        method: @fetchModerators
        client
        rest
      }

  fetchModeratorsWithEmail$: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success:(client, rest...) ->
      @baseFetcherOfGroupStaff {
        method      : @fetchModerators
        fetchEmail  : yes
        client
        rest
      }

  fetchBlockedAccounts$: permit
    advanced: [
      { permission: 'list members' }
      { permission: 'list members', superadmin: yes }
    ]
    success:(client, rest...) ->
      @baseFetcherOfGroupStaff {
        method: @fetchBlockedAccounts
        client
        rest
      }

  fetchBlockedAccountsWithEmail$: permit
    advanced: [
      { permission: 'list members' }
      { permission: 'list members', superadmin: yes }
    ]
    success:(client, rest...) ->
      @baseFetcherOfGroupStaff {
        method      : @fetchBlockedAccounts
        fetchEmail  : yes
        client
        rest
      }


  fetchApiTokens$: permit
    advanced: PERMISSION_EDIT_GROUPS
    success: (client, callback) ->
      JApiToken = require '../apitoken'
      selector  = { group : @getAt 'slug' }

      JApiToken.some selector, {}, (err, apiTokens) ->
        return callback err, []  if err or not apiTokens
        JGroup.mergeApiTokensWithUsername apiTokens, callback


  baseFetcherOfGroupStaff: (options) ->

    { method, client, rest, fetchEmail }  = options

    # when max limit is over 20 it starts giving "call stack exceeded" error
    [selector, options, callback] = Module.limitEdges 10, 19, rest

    # delete options.targetOptions
    options.client                = client

    method.call this, selector, options, (err, records = []) =>
      return callback err, records  if err or not records or not fetchEmail

      @mergeAccountsWithEmail records, (err, accounts) ->
        return callback err, accounts


  fetchResources$: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success: (client, rest...) ->

      [selector, options, callback] = Module.limitEdges 10, 19, rest

      if client.context.group isnt @getAt 'slug'
        return callback new KodingError 'Access denied'

      if selector.searchFor?
        selector.title = ///#{selector.searchFor}///
        delete selector.searchFor

      ComputeProvider = require '../computeproviders/computeprovider'
      ComputeProvider.fetchGroupResources this, selector, options, callback


  # this method contains copy/pasted code from jAccount.findSuggestions method.
  # It is a workaround, and will be changed after elasticsearch implementation. CtF
  searchMembers: permit 'list members',
    success: (client, seed, options = {}, callback) ->
      cleanSeed = seed.replace(/[^\w\s-]/).trim()
      seed = RegExp cleanSeed, 'i'

      names = seed.toString().split('/')[1].replace('^', '').split ' '
      names.push names.first  if names.length is 1

      selector =
        $or : [
            ({ 'profile.nickname'  : seed })
            ({ 'profile.firstName' : new RegExp '^'+names.slice(0, -1).join(' '), 'i' })
            ({ 'profile.lastName'  : new RegExp '^'+names.last, 'i' })
          ]
        type    :
          $in   : ['registered', null]
          # CtF null does not effect the results here, it only searches for registered ones.
          # probably jraphical problem, because the query correctly works in mongo

      { limit, skip } = options
      options.sort  = { 'meta.createdAt' : -1 }
      options.limit = Math.min limit ? 10, 15
      # CtF @fetchMembers first fetches all group-member relationships, and then filters accounts with found targetIds.
      # As a result searching groups with large number of members is very time consuming. For now the only group
      # with large member count is koding, so i have seperated it here. as a future work hopefully we will make
      # the search queries via elasticsearch.
      if @slug is 'koding'
        JAccount = require '../account'
        JAccount.some selector, options, callback
      else
        options.targetOptions = { options, selector }

        @fetchMembers {}, options, callback


  fetchHomepageView: (options, callback) ->
    { account, section } = options
    kallback = =>
      @fetchMembershipPolicy (err, policy) =>
        if err then callback err
        else
          homePageOptions = extend options, {
            @slug
            @title
            policy
            @avatar
            @body
            @counts
            @customize
          }
          prefix = if account?.type is 'unregistered' then 'loggedOut' else 'loggedIn'
          JGroup.render[prefix].groupHome homePageOptions, callback

    if @visibility is 'hidden' and section isnt 'Invitation'
      @isMember account, (err, isMember) ->
        return callback err if err
        if isMember then kallback()
        else do callback
    else
      kallback()


  createMembershipPolicy:(requestType, queue, callback) ->
    [callback, queue] = [queue, callback]  unless callback
    queue ?= []

    JMembershipPolicy = require './membershippolicy'
    membershipPolicy  = new JMembershipPolicy
    membershipPolicy.approvalEnabled = no  if requestType is 'by-invite'

    queue.push(

      (next) ->
        membershipPolicy.save next

      (next) =>
        @addMembershipPolicy membershipPolicy, next

    )

    async.series queue, (err) ->
      return callback err  if err
      return callback null, membershipPolicy


  destroyMemebershipPolicy:(callback) ->
    @fetchMembershipPolicy (err, policy) ->
      if err then callback err
      else unless policy?
        callback new KodingError '404 Membership policy not found'
      else policy.remove callback


  modify     : permit
    advanced : [
      { permission: 'edit own groups', validateWith : Validators.group.admin }
      { permission: 'edit groups',     superadmin   : yes }
    ]
    success  : (client, data, callback) ->

      # it's not allowed to change followings
      blacklist  = ['slug', 'slug_', 'config', '_activeLimit']
      data[item] = null  for item in blacklist when data[item]?

      notifyOptions =
        group   : client?.context?.group
        target  : 'group'

      { reviveGroupLimits } = require '../computeproviders/computeutils'

      reviveGroupLimits this, (err, group) =>

        # we need to make sure if given stack template is
        # valid for the current group limit ~ GG
        templates = data.stackTemplates
        if templates?.length > 0 and group._activeLimit
          ComputeProvider = require '../computeproviders/computeprovider'
          ComputeProvider.validateTemplates client, templates, group, (err) =>
            return callback err  if err
            @updateAndNotify notifyOptions, { $set: data }, callback
        else
          @updateAndNotify notifyOptions, { $set: data }, callback


  setLimit    : permit
    advanced : [{ permission: 'edit groups', superadmin: yes }]
    success  : (client, data, callback) ->

      if (@getAt 'slug') is 'koding'
        return callback new KodingError \
          'Setting a limit on koding is not allowed'

      dataToUpdate = { 'config.limitOverrides' : data.overrides }

      # Allow koding admins to set a testlimit on dev environments
      if data.limit and KONFIG.environment isnt 'production'
        dataToUpdate['config.testlimit'] = data.limit

      if data.limit is 'nolimit' and not data.overrides
        dataToUpdate['config.testlimit'] = {}
        @update { $unset: dataToUpdate }, callback
      else
        @update { $set: dataToUpdate }, callback


  modifyMembershipPolicy: permit
    advanced: PERMISSION_EDIT_GROUPS
    success: (client, formData, callback) ->
      @fetchMembershipPolicy (err, policy) ->
        if err then callback err
        else policy.update { $set: formData }, callback


  toggleFeature: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success:(client, options, callback) ->
      if not options.feature or not options.role or not options.operation
        return callback new KodingError 'request is not valid'

      @disabledFeatures = {}  unless @disabledFeatures
      @disabledFeatures[options.role] = []  unless @disabledFeatures[options.role]

      if options.operation is 'disable'
        if options.feature not in @disabledFeatures?[options.role]
          @disabledFeatures[options.role].push options.feature
          return @update callback
        else
          return callback new KodingError 'item is not in the list '
      else

        if options.feature not in @disabledFeatures?[options.role]
          return callback new KodingError 'item is not in the list'
        else
          ops = (feature for feature in @disabledFeatures?[options.role] when feature isnt options.feature)
          @disabledFeatures[options.role] = ops
          return @update callback


  canEditGroup: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success: (client, callback) ->
      callback null, yes
    failure: (client, callback) ->
      callback null, no


  @canReadGroupActivity = permit 'read group activity'
  canReadGroupActivity  : permit 'read group activity'
  @canListMembers       = permit
    advanced: [
      { permission: 'list members' }
      { permission: 'list members', superadmin: yes }
    ]

  canOpenGroup: permit 'open group',
    failure:(client, callback) ->
      @fetchMembershipPolicy (err, policy) ->
        explanation = policy?.explain() ?
                      err?.message ?
                      'No membership policy!'
        clientError = err ? new KodingError explanation
        clientError.accessCode = policy?.code ?
          if err then ERROR_UNKNOWN
          else if explanation? then ERROR_POLICY
          else ERROR_NO_POLICY
        callback clientError, no


  isMember: (account, callback) ->

    return callback new Error 'No account found!'  unless account
    selector =
      sourceId  : @getId()
      targetId  : account._id
      as        : 'member'
    Relationship.count selector, (err, count) ->
      if err then callback err
      else callback null, (if count is 0 then no else yes)


  approveMember:(member, roles, callback) ->
    [callback, roles] = [roles, callback]  unless callback
    roles ?= ['member']

    @fetchBlockedAccount { targetId: member.getId() }, (err, account_) =>
      return callback err if err
      return callback new KodingError 'This account is blocked'  if account_

      kallback = =>
        callback()
        @updateCounts()
        @emit 'MemberAdded', member  if 'member' in roles

      queue = roles.map (role) => (fin) =>
        @addMember member, role, fin

      # We were creating group member VMs here before
      # I've deleted them, ask me if you need more information ~ GG
      async.parallel queue, -> kallback()

  each:(selector, rest...) ->
    selector.visibility = 'visible'
    Module::each.call this, selector, rest...


  fetchRolesHelper: (account, callback) ->
    client = { connection: { delegate : account } }
    @fetchMyRoles client, (err, roles) =>
      if err then callback err
      else if 'member' in roles or 'admin' in roles
        callback null, roles
      else
        options =
          targetOptions:
            selector   : { koding: { username: account.profile.nickname } }
        @fetchInvitationRequest {}, options, (err, request) ->
          if err then callback err
          else unless request? then callback null, ['guest']
          else callback null, ["invitation-#{request.status}"]


  updateCounts: ->
    # remove this guest shit if required
    if @getId().toString() is '51f41f195f07655e560001c1'
      return

    Relationship.count
      as         : 'member'
      targetName : 'JAccount'
      sourceId   : @getId()
      sourceName : 'JGroup'
    , (err, count) =>
      @update ({ $set: { 'counts.members': count } }), ->


  leave$: secure (client, options, callback) ->

    password = options?.password
    account = client?.connection?.delegate

    unless account or password
      return callback new KodingError 'Error occured while leaving team'

    account.fetchUser (err, user) =>
      unless err
        unless user.checkPassword password
          return callback new KodingError 'Your password didn\'t match with our records'
        else
          @leave client, options, callback


  leave: (client, options, callback) ->

    [callback, options] = [options, callback] unless callback

    if @slug in ['koding', 'guests']
      return callback new KodingError "It's not allowed to leave this group"

    @fetchMyRoles client, (err, roles) =>
      return callback err if err

      if 'owner' in roles
        return callback new KodingError 'As owner of this group, you must first transfer ownership to someone else!'

      Joinable = require '../../traits/joinable'

      kallback = (err) =>
        @updateCounts()

        { profile: { nickname } } = client.connection.delegate

        return  unless nickname

        JSession = require '../session'
        JSession.remove { username: nickname, groupName: @slug }, callback

      queue = roles.map (role) => (fin) =>
        Joinable::leave.call this, client, { as:role }, fin

      async.parallel queue, kallback

  kickMember: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success: (client, accountId, callback) ->

      { connection: { delegate } } = client

      if @slug is 'koding'
        return callback new KodingError 'Koding group is mandatory'

      JAccount = require '../account'
      JAccount.one { _id:accountId }, (err, account) =>
        return callback err if err

        if delegate.getId().equals account._id
          return callback new KodingError 'You cannot kick yourself, try leaving the group!'

        @fetchRolesByAccount account, (err, roles) =>
          return callback err if err

          if 'owner' in roles
            return callback new KodingError 'You cannot kick the owner of the group!'

          kallback = (err) =>
            return callback err  if err
            contents = { group: client.context.group }

            # send this event for artifact removal
            @emit 'MemberRemoved', account, requester = delegate

            # send notification for kicking
            account.sendNotification 'UserKicked', contents

            JSession = require '../session'
            # remove their sessions
            JSession.remove {
              username  : account.profile.nickname
              groupName : client.context.group
            }, (err) -> callback err

          queue = roles.map (role) => (fin) =>
            @removeMember account, role, (err) =>
              return fin err  if err
              @updateCounts()
              fin()

          # add current user into blocked accounts
          queue.push (fin) =>
            # addBlockedAccount is generated by bongo
            @addBlockedAccount account, fin

          async.parallel queue, kallback
  ###*
   * UnblockMember removes the blockage on the member for joining to a group.
   *
   * @param {Object} client - Session context.
   * @param {String} accountId - Id of the account for unblocking.
   * @param {Function} callback - Callback.
  ###
  unblockMember: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success: (client, options, callback) ->

      if typeof options is 'string'
        accountId = options
        removeUserFromTeam = no
      else
        accountId = options.id
        removeUserFromTeam = options.removeUserFromTeam

      JAccount = require '../account'
      JAccount.one { _id: accountId }, (err, account) =>
        return callback err  if err
        return callback new KodingError 'There is no such user'  unless account
        # removeBlockedAccount is generated by bongo
        @removeBlockedAccount account, (err) =>
          return callback err  if err
          callback err  if removeUserFromTeam
          @addMember account, {}, callback  unless removeUserFromTeam


  transferOwnership: permit
    advanced: [
      { permission: 'grant permissions' }
      { permission: 'grant permissions', superadmin: yes }
    ]
    success: (client, accountId, callback) ->
      JAccount = require '../account'

      { delegate } = client.connection
      if delegate.getId().equals accountId
        return callback new KodingError 'You cannot transfer ownership to yourself, concentrate and try again!'

      Relationship.one {
        targetId: delegate.getId(),
        sourceId: @getId(),
        as      : 'owner'
      }, (err, owner) =>
        return callback err if err
        return callback new KodingError 'You must be the owner to perform this action!' unless owner

        JAccount.one { _id:accountId }, (err, account) =>
          return callback err if err

          @fetchRolesByAccount account, (err, newOwnersRoles) =>
            return callback err if err

            kallback = (err) =>
              @updateCounts()
              callback err

            # give rights to new owner
            queue = difference(['member', 'admin'], newOwnersRoles).map (role) => (fin) =>
              @addMember account, role, fin

            async.parallel queue, (err) ->
              return kallback err  if err
              # transfer ownership
              owner.update { $set: { targetId: account.getId() } }, kallback

  ensureUniquenessOfRoleRelationship:(target, options, fallbackRole, roleUnique, callback) ->
    unless callback
      callback   = roleUnique
      roleUnique = no

    if 'string' is typeof options
      as = options
    else if options?.as
      { as } = options
    else
      as = fallbackRole

    # remove this
    if @getId().toString() is '51f41f195f07655e560001c1'
      return callback null

    selector =
      targetName : target.bongo_.constructorName
      sourceId   : @getId()
      sourceName : @bongo_.constructorName
      as         : as

    unless roleUnique
      selector.targetId = target.getId()

    Relationship.count selector, (err, count) ->
      if err then callback err
      else if count > 0 then callback new KodingError 'This relationship already exists'
      else callback null

  oldAddMember = @::addMember
  addMember:(target, options, callback) ->
    @ensureUniquenessOfRoleRelationship target, options, 'member', (err) =>
      if err then callback err
      else oldAddMember.call this, target, options, callback

  oldAddAdmin = @::addAdmin
  addAdmin:(target, options, callback) ->
    @ensureUniquenessOfRoleRelationship target, options, 'admin', (err) =>
      if err then callback err
      else oldAddAdmin.call this, target, options, callback

  oldAddOwner = @::addOwner
  addOwner:(target, options, callback) ->
    @ensureUniquenessOfRoleRelationship target, options, 'owner', yes, (err) =>
      if err then callback err
      else oldAddOwner.call this, target, options, callback

  destroy    : permit
    advanced : [
      { permission: 'edit own groups', validateWith : Validators.own }
      { permission: 'edit groups',     superadmin   : yes }
    ]
    success  : (client, callback) ->

      JName = require '../name'

      removeHelper = (model, err, next) ->
        return next err  if err
        return next()  unless model

        model.remove (err) -> next err

      removeHelperMany = (klass, models, err, next) ->
        return next err  if err
        return next()    if not models or models.length < 1

        ids = (model._id for model in models)
        klass.remove ({ _id: { $in: ids } }), (err) -> next err

      async.series [

        (next) =>
          JName.one { name: @slug }, (err, name) ->
            removeHelper name, err, next

        (next) =>
          @fetchPermissionSet (err, permSet) ->
            removeHelper permSet, err, next

        (next) =>
          @fetchDefaultPermissionSet (err, permSet) ->
            removeHelper permSet, err, next

        (next) =>
          @fetchMembershipPolicy (err, policy) ->
            removeHelper policy, err, next

        (next) =>
          JInvitation = require '../invitation'
          JInvitation.remove { groupName: @slug }, (err) ->
            next err

        (next) =>
          @fetchTags (err, tags) ->
            JTag = require '../tag'
            removeHelperMany JTag, tags, err, next

        (next) =>
          ComputeProvider = require '../computeproviders/computeprovider'
          ComputeProvider.destroyGroupResources this, -> next()

        (next) =>
          JSession = require '../session'
          @sendNotification 'GroupDestroyed', @slug, =>
            JSession.remove { groupName: @slug }, (err) ->
              next err

        (next) =>
          @constructor.emit 'GroupDestroyed', this
          next()

        (next) =>
          @remove (err) -> next err

      ], callback


  sendNotificationToAdmins: (event, contents) ->

    @fetchAdmins (err, admins) =>

      unless err
        relationship =  {
          as         : event,
          sourceName : contents.subject.constructorName,
          sourceId   : contents.subject.id,
          targetName : contents.member.constructorName,
          targetId   : contents.member.id,
        }

        contents.relationship = relationship
        contents.origin       = contents.subject
        contents.origin.slug  = @slug
        contents.group        = @slug
        contents.actorType    = event
        contents[event]       = contents.member


        queue = admins.map (admin) => (next) =>
          contents.recipient = admin
          @notify admin, event, contents, next

        { notifyByUsernames } = require '../notify'

        usernames = admins.map (admin) -> admin.profile.nickname

        notifyByUsernames usernames, 'NewMemberJoinedToGroup', contents

        async.series queue


  @each$ = (selector, options, callback) ->
    selector.visibility = 'visible'
    @each selector, options, callback


  fetchPermissionSetOrDefault: (callback) ->
    @fetchPermissionSet (err, permissionSet) =>
      callback err, null if err
      if permissionSet
        callback null, permissionSet
      else
        @fetchDefaultPermissionSet callback


  createSocialApiChannels: (client, callback) ->

    @fetchOwner (err, owner) =>
      return callback err if err?
      unless owner
        return callback { message: "Owner not found for #{@slug} group" }

      owner.createSocialApiId (err, socialApiId) =>
        return callback err if err?
        # required data for creating a channel
        privacy = if @slug is 'koding' then 'public' else 'private'

        options =
          creatorId       : socialApiId
          privacyConstant : privacy

        @createGroupChannel client, options, (err, groupChannelId) =>
          return callback err  if err?

          # announcement channel will only be created for koding channel
          if @slug is 'koding'

            @createAnnouncementChannel client, options, (err, announcementChannelId) ->
              return callback err if err?

              return callback null, {
                # channel id for #public - used as group channel
                socialApiChannelId             : groupChannelId,
                # channel id for #koding - used for announcements
                socialApiAnnouncementChannelId : announcementChannelId
              }

          else
            @createDefaultChannel client, options, (err, defaultChannelId) ->
              return callback err if err?

              return callback null, {
                socialApiChannelId: groupChannelId
                socialApiDefaultChannelId: defaultChannelId
              }


  createGroupChannel:(client, options, callback) ->
    options.name = 'public'
    options.varName = 'socialApiChannelId'
    options.typeConstant = 'group'

    return @createSocialAPIChannel client, options, callback

  createAnnouncementChannel:(client, options, callback) ->
    options.name = 'changelog'
    options.varName = 'socialApiAnnouncementChannelId'
    options.typeConstant = 'announcement'

    return @createSocialAPIChannel client, options, callback

  createDefaultChannel:(client, options, callback) ->
    options.name = @slug
    options.varName = 'socialApiDefaultChannelId'
    options.typeConstant = 'topic'

    return @createSocialAPIChannel client, options, callback


  createSocialAPIChannel:(client, options, callback) ->
    { varName, name, typeConstant, creatorId, privacyConstant } = options

    return callback null, @[varName]  if @[varName]

    defaultChannel =
      name            : name or @slug
      creatorId       : creatorId
      groupName       : @slug
      typeConstant    : typeConstant
      privacyConstant : privacyConstant

    { doRequest } = require '../socialapi/helper'
    doRequest 'createChannel', client, defaultChannel, (err, channel) =>
      return callback err if err

      op = { $set: {}, $push: {} }
      op.$set[varName] = channel.channel.id
      op.$push['defaultChannels'] = channel.channel.id

      @update op, (err) ->
        return callback err if err
        return callback null, channel.id


  mergeAccountsWithEmail: (accounts, callback) ->

    JUser     = require '../user'
    usernames = accounts.map (account) -> account.profile.nickname

    JUser.some { username: { $in: usernames } }, {}, (err, users) ->

      return callback err, []  if err or not users

      for account in accounts
        for user in users
          if account.profile.nickname is user.username
            account.profile.email = user.email

      return callback null, accounts


  @mergeApiTokensWithUsername: (apiTokens, callback) ->

    JAccount  = require '../account'
    originIds = apiTokens.map (apiToken) -> apiToken.originId

    JAccount.some { _id: { $in: originIds } }, {}, (err, accounts) ->
      return callback err, []  if err or not accounts

      accounts.forEach (account) ->
        apiTokens.forEach (apiToken) ->
          if account._id.toString() is apiToken.originId.toString?()
            apiToken.username = account.profile.nickname

      return callback null, apiTokens


  @sendStackAdminMessageNotification: (data, callback) ->

    { slug, stackIds, message, type } = data

    JGroup.one { slug }, (err, group) ->
      callback err  if err
      group.sendNotification(
        'StackAdminMessageCreated',
        { stackIds, message, type }
        callback
      )
