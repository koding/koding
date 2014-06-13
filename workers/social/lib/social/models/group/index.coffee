{Module}     = require 'jraphical'
{difference} = require 'underscore'

module.exports = class JGroup extends Module

  [ERROR_UNKNOWN, ERROR_NO_POLICY, ERROR_POLICY] = [403010, 403001, 403009]

  {Relationship} = require 'jraphical'

  {Inflector, ObjectId, ObjectRef, secure, daisy, race, dash, signature} = require 'bongo'

  JPermissionSet = require './permissionset'
  {permit}       = JPermissionSet

  JAccount     = require '../account'
  JPaymentPack = require '../payment/pack'

  KodingError    = require '../../error'
  Validators     = require './validators'
  {throttle, extend}     = require 'underscore'

  PERMISSION_EDIT_GROUPS = [
    {permission: 'edit groups'}
    {permission: 'edit own groups', validateWith: Validators.own}
  ]

  @trait __dirname, '../../traits/filterable'
  @trait __dirname, '../../traits/followable'
  @trait __dirname, '../../traits/taggable'
  @trait __dirname, '../../traits/protected'
  @trait __dirname, '../../traits/joinable'
  @trait __dirname, '../../traits/slugifiable'
  @trait __dirname, '../../traits/notifying'

  @share()

  @set
    softDelete      : yes
    slugifyFrom     : 'slug'
    slugTemplate    : '#{slug}'
    feedable        : no
    memberRoles     : ['admin','moderator','member','guest']
    permissions     :
      'grant permissions'                 : []
      'open group'                        : ['member','moderator']
      'list members'                      :
        public                            : ['moderator', 'member']
        private                           : ['moderator', 'member']
      'read group activity'               :
        public                            : ['guest','member','moderator']
        private                           : ['member','moderator']
      'create groups'                     : ['moderator']
      'edit groups'                       : ['moderator']
      'edit own groups'                   : ['member','moderator']
      'query collection'                  : ['member','moderator']
      'update collection'                 : ['moderator']
      'assure collection'                 : ['moderator']
      'remove documents from collection'  : ['moderator']
      'view readme'                       : ['guest','member','moderator']
      'send invitations'                  : ['moderator']
    indexes         :
      slug          : 'unique'
    sharedEvents    :
      static        : [
        { name: 'MemberAdded',      filter: -> null }
        { name: 'MemberRemoved',    filter: -> null }
        { name: 'MemberRolesChanged' }
        { name: 'GroupDestroyed' }
        { name: 'broadcast' }
        { name: 'updateInstance' }
        { name: 'RemovedFromCollection' }

      ]
      instance      : [
        { name: 'GroupCreated' }
        { name: 'MemberAdded',      filter: -> null }
        { name: 'MemberRemoved',    filter: -> null }
        { name: 'NewInvitationRequest' }
        { name: 'updateInstance' }
        { name: 'RemovedFromCollection' }
      ]
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
        __resetAllGroups:
          (signature Function)
        fetchMyMemberships: [
          (signature [ObjectId], Function)
          (signature [ObjectId], String, Function)
        ]
        __importKodingMembers:
          (signature Function)
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
        createRole:
          (signature Object, Function)
        updatePermissions:
          (signature Object, Function)
        fetchMembers: [
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
        requestAccess:
          (signature Function)
        addCustomRole:
          (signature Object, Function)
        resolvePendingRequests:
          (signature Function)
        fetchMembershipStatuses:
          (signature Function)
        fetchAdmin:
          (signature Function)
        inviteByEmail:
          (signature String, Object, Function)
        inviteByEmails:
          (signature String, Object, Function)
        isMember:
          (signature Object, Function)
        kickMember:
          (signature String, Function)
        transferOwnership:
          (signature String, Function)
        fetchRolesByClientId: [
          (signature Function)
          (signature String, Function)
        ]
        fetchInvitationsFromGraph:
          (signature String, Object, Function)
        countInvitationsFromGraph:
          (signature String, Object, Function)
        fetchMembersFromGraph:
          (signature Object, Function)
        remove:
          (signature Function)
        bulkApprove:
          (signature Number, Object, Function)
        fetchNewestMembers: [
          (signature Function)
          (signature Object, Function)
          (signature Object, Object, Function)
        ]
        countMembers:
          (signature Function)
        makePayment:
          (signature Object, Function)
        # # addProduct:
        # (signature)
        # # deleteProduct:
        # (signature)
        fetchProducts: [
          (signature Function)
          (signature String, Function)
          (signature String, Object, Function)
        ]
        saveInviteMessage: [
          (signature String, String)
          (signature String, String, Function)
        ]
        redeemInvitation:
          (signature String, Function)
        fetchPaymentMethod:
          (signature Function)
        linkPaymentMethod:
          (signature String, Function)
        unlinkPaymentMethod:
          (signature String, Function)
        addSubscription:
          (signature String, Function)
        fetchSubscription:
          (signature Function)
        fetchPermissionSetOrDefault:
          (signature Function)
        fetchUserStatus:
          (signature Object, Function)
        fetchInvitationsByStatus:
          (signature Object, Function)
    schema          :
      title         :
        type        : String
        required    : yes
      body          : String
      # channelId for mapping social API
      # to internal usage
      socialApiChannelId: String
      avatar        : String
      slug          :
        type        : String
        validate    : require('../name').validateName
        set         : (value)-> value.toLowerCase()
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
      payment       :
        plan        : String
        paymentQuota: Number

      stackTemplates: [ ObjectId ]

    broadcastableRelationships : [
      'member', 'moderator', 'admin'
      'owner', 'tag', 'role'
    ]
    relationships   :
      bundle        :
        targetType  : 'JGroupBundle'
        as          : 'owner'
      permissionSet :
        targetType  : JPermissionSet
        as          : 'owner'
      defaultPermissionSet:
        targetType  : JPermissionSet
        as          : 'default'
      member        :
        targetType  : 'JAccount'
        as          : 'member'
      moderator     :
        targetType  : 'JAccount'
        as          : 'moderator'
      admin         :
        targetType  : 'JAccount'
        as          : 'admin'
      owner         :
        targetType  : 'JAccount'
        as          : 'owner'
      application   :
        targetType  : 'JNewApp'
        as          : 'owner'
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
      invitationRequest:
        targetType  : 'JInvitationRequest'
        as          : 'owner'
      invitation:
        targetType  : 'JInvitation'
        as          : 'owner'
      vm            :
        targetType  : 'JVM'
        as          : 'owner'
      paymentMethod :
        targetType  : 'JPaymentMethod'
        as          : 'linked payment method'
      product       :
        targetType  : 'JPaymentProduct'
        as          : 'product'
      pack          :
        targetType  : 'JPaymentPack'
        as          : 'product pack'
      plan          :
        targetType  : 'JPaymentPlan'
        as          : 'group plan'
      subscription  :
        targetType  : 'JPaymentSubscription'
        as          : 'payment plan subscription'
      credential    :
        as          : ['owner', 'user']
        targetType  : 'JCredential'

  constructor:->
    super

    @on 'MemberAdded', (member)->
      @constructor.emit 'MemberAdded', { group: this, member }
      unless @slug is 'guests'
        @sendNotificationToAdmins 'GroupJoined',
          actionType : 'groupJoined'
          actorType  : 'member'
          subject    : ObjectRef(this).data
          member     : ObjectRef(member).data
        @broadcast 'MemberJoinedGroup',
          member : ObjectRef(member).data

    @on 'MemberRemoved', (member)->
      @constructor.emit 'MemberRemoved', { group: this, member }
      unless @slug is 'guests'
        @sendNotificationToAdmins 'GroupLeft',
          actionType : 'groupLeft'
          actorType  : 'member'
          subject    : ObjectRef(this).data
          member     : ObjectRef(member).data
        @broadcast 'MemberLeftGroup',
          member : ObjectRef(member).data

    @on 'MemberRolesChanged', (member)->
      @constructor.emit 'MemberRolesChanged', { group: this, member }

  @__importKodingMembers = secure (client, callback)->
    JAccount = require '../account'
    {delegate} = client.connection
    count = 0
    if delegate.can 'migrate-koding-users'
      @one slug:'koding', (err, koding)->
        if err then callback err
        else
          JAccount.each {}, {}, (err, account)->
            if err
              callback err
            else unless account?
              callback null
            else
              isMember =
                sourceId  : koding.getId()
                targetId  : account.getId()
                as        : 'member'
              Relationship.count isMember, (err, count)->
                if err then callback err
                else if count is 0
                  process.nextTick ->
                    koding.approveMember account, ->
                      console.log "added member: #{account.profile.nickname}"

  @render        :
    loggedIn     :
      kodingHome : require '../../render/loggedin/kodinghome'
      groupHome  : require '../../render/loggedin/grouphome'
      subPage    : require '../../render/loggedin/subpage'
    loggedOut    :
      groupHome  : require '../../render/loggedout/grouphome'
      kodingHome : require '../../render/loggedout/kodinghome'
      subPage    : require '../../render/loggedout/subpage'

  @__resetAllGroups = secure (client, callback)->
    {delegate} = client.connection
    @drop callback if delegate.can 'reset groups'

  @fetchParentGroup =(source, callback)->
    Relationship.someData {
      targetName  : @name
      sourceId    : source.getId?()
      sourceType  : 'function' is typeof source and source.name
    }, {targetId: 1}, (err, cursor)=>
      if err
        callback err
      else
        cursor.nextObject (err, rel)=>
          if err
            callback err
          else unless rel
            callback null
          else
            @one {_id: targetId}, callback

  @create = do ->

    save_ =(label, model, queue, callback)->
      model.save (err)->
        if err then callback err
        else
          console.log "#{label} is saved"
          queue.next()

    create = (client, groupData, owner, callback) ->
      JPermissionSet        = require './permissionset'
      JMembershipPolicy     = require './membershippolicy'
      JName                 = require '../name'
      group                 = new this groupData
      group.privacy         = 'private'
      defaultPermissionSet  = new JPermissionSet {}, {privacy: group.privacy}

      queue = [
        -> group.useSlug group.slug, (err, slug)->
          if err then callback err
          else unless slug?
            callback new KodingError "Couldn't claim the slug!"
          else
            console.log "created a slug #{slug.slug}"
            group.slug  = slug.slug
            group.slug_ = slug.slug
            queue.next()
        -> save_ 'group', group, queue, (err)->
           if err
             JName.release group.slug, -> callback err
           else
             queue.next()
        -> group.addMember owner, (err)->
            if err then callback err
            else
              console.log 'member is added'
              queue.next()
        -> group.addAdmin owner, (err)->
            if err then callback err
            else
              console.log 'admin is added'
              queue.next()
        -> group.addOwner owner, (err)->
            if err then callback err
            else
              console.log 'owner is added'
              queue.next()
        -> save_ 'default permission set', defaultPermissionSet, queue,
                  callback
        -> group.addDefaultPermissionSet defaultPermissionSet, (err)->
            if err then callback err
            else
              console.log 'permissionSet is added'
              queue.next()
        -> group.addDefaultRoles (err)->
            if err then callback err
            else
              console.log 'roles are added'
              queue.next()
      ]

      if 'private' is group.privacy
        queue.push -> group.createMembershipPolicy groupData.requestType, -> queue.next()

      queue.push =>
        @emit 'GroupCreated', { group, creator: owner }
        callback null, group

      daisy queue

  @create$ = secure (client, formData, callback)->
    {delegate} = client.connection

    subOptions = targetOptions: selector: tags: "custom-plan"
    delegate.fetchSubscription null, subOptions, (err, subscription) =>
      return callback err  if err
      return callback new KodingError "Subscription is not found"  unless subscription
      subscription.debitPack tag: "group", (err) =>
        return callback err  if err
        @create client, formData, delegate, (err, group) ->
          return callback err if err
          group.addSubscription subscription, (err) ->
            return callback err  if err
            callback null, { group, subscription }

  @findSuggestions = (client, seed, options, callback)->
    {limit, blacklist, skip}  = options

    @some
      title      : seed
      _id        :
        $nin     : blacklist
      visibility : 'visible'
    ,
      skip
      limit
      sort       : 'title' : 1
    , callback

  # currently groups in a group show global groups, so it does not
  # make sense to allow this method based on current group's permissions
  @byRelevance$ = secure (client, seed, options, callback)->
    @byRelevance client, seed, options, callback

  @fetchSecretChannelName =(groupSlug, callback)->
    JName = require '../name'
    JName.fetchSecretName groupSlug, (err, secretName, oldSecretName)->
      if err then callback err
      else callback null, "group.secret.#{secretName}",
        if oldSecretName then "group.secret.#{oldSecretName}"

  @cycleChannel =do->
    cycleChannel = (groupSlug, callback=->)->
      JName = require '../name'
      JName.cycleSecretName groupSlug, (err, oldSecretName, newSecretName)=>
        if err then callback err
        else
          routingKey = "group.secret.#{oldSecretName}.cycleChannel"
          @emit 'broadcast', routingKey, null
          callback null
    return throttle cycleChannel, 5000

  cycleChannel:(callback)-> @constructor.cycleChannel @slug, callback

  @broadcast =(groupSlug, event, message)->
    if message?
      event = ".#{event}"
    else
      [message, event] = [event, message]
      event = ''
    @fetchSecretChannelName groupSlug, (err, secretChannelName, oldSecretChannelName)=>
      if err? then console.error err
      else unless secretChannelName? then console.error 'unknown channel'
      else
        @emit 'broadcast', "#{oldSecretChannelName}#{event}", message  if oldSecretChannelName
        @emit 'broadcast', "#{secretChannelName}#{event}", message
        @emit 'notification', "#{groupSlug}#{event}", {
          routingKey  : groupSlug
          contents    : message
          event       : 'feed-new'
        }

  broadcast:(message, event)->
    @constructor.broadcast @slug, message, event

  changeMemberRoles: permit 'grant permissions',
    success:(client, targetId, roles, callback)->
      remove = []
      sourceId = @getId()
      roles.push 'member'  unless 'member' in roles
      Relationship.some {targetId, sourceId}, {}, (err, rels)->
        return callback err  if err

        for rel in rels
          if rel.as in roles then roles.splice roles.indexOf(rel.as), 1
          else remove.push rel._id

        if remove.length > 0
          Relationship.remove _id: $in: remove, (err)-> console.log 'removed'; callback err  if err

        queue = roles.map (role)->->
          (new Relationship
            targetName  : 'JAccount'
            targetId    : targetId
            sourceName  : 'JGroup'
            sourceId    : sourceId
            as          : role
          ).save (err)->
            callback err  if err
            queue.fin()
        dash queue, callback

  addDefaultRoles:(callback)->
    group = this
    JGroupRole = require './role'
    JGroupRole.all {isDefault: yes}, (err, roles)->
      if err then callback err
      else
        queue = roles.map (role)->->
          group.addRole role, queue.fin.bind queue
        dash queue, callback

  updatePermissions: permit 'grant permissions',
    success:(client, permissions, callback=->)->
      @fetchPermissionSet (err, permissionSet)=>
        return callback err if err
        if permissionSet
          permissionSet.update $set:{permissions}, callback
        else
          permissionSet = new JPermissionSet {permissions, isCustom: true}
          permissionSet.save (err) =>
            return callback err if err
            @addPermissionSet permissionSet, (err)->
              return callback err if err
              console.log 'permissionSet is added'
              callback null

  fetchPermissions:do->
    fixDefaultPermissions_ =(model, permissionSet, callback)->
      # It was lately recognized that we needed to have a default permission
      # set that is created at the time of group creation, because other
      # permissions may be roled out over time, and it is best to be secure by
      # default.  Without knowing which permissions were present at the time
      # of group creation, we may inadvertantly expose dangerous permissions
      # to underprivileged roles.  We will create this group's "default
      # permissions" by cloning the group's current permission set. C.T.
      defaultPermissionSet = permissionSet.clone()
      defaultPermissionSet.save (err)->
        if err then callback err
        else model.addDefaultPermissionSet defaultPermissionSet, (err)->
          if err then callback err
          else callback null, defaultPermissionSet

    fetchPermissions = permit 'grant permissions',
      success:(client, callback)->
        {permissionsByModule} = require '../../traits/protected'
        {delegate}            = client.connection
        permissionSet         = null
        defaultPermissionSet  = null
        daisy queue = [
          => @fetchPermissionSet (err, model)->
              if err then callback err
              else
                permissionSet = model
                queue.next()
          => @fetchDefaultPermissionSet (err, model)=>
              if err then callback err
              else if model?
                console.log 'already had defaults'
                defaultPermissionSet = model
                permissionSet = model unless permissionSet
                queue.next()
              else
                console.log 'needed defaults fixed'
                fixDefaultPermissions_ this, permissionSet, (err, newModel)->
                  defaultPermissionSet = newModel
                  queue.next()
          -> callback null, {
              permissionsByModule
              permissions         : permissionSet.permissions
              defaultPermissions  : defaultPermissionSet.permissions
            }
        ]

  fetchRolesByAccount:(account, callback)->
    Relationship.someData {
      targetId: account.getId()
      sourceId: @getId()
    }, {as:1}, (err, cursor)->
      if err then callback err
      else
        cursor.toArray (err, arr)->
          if err then callback err
          else
            roles = if arr.length > 0 then (doc.as for doc in arr) else ['guest']
            callback null, roles

  fetchMyRoles: secure (client, callback)->
    @fetchRolesByAccount client.connection.delegate, callback

  fetchUserRoles: permit 'grant permissions',
    success:(client, ids, callback)->
      [callback, ids] = [ids, callback]  unless callback
      @fetchRoles (err, roles)=>
        roleTitles = (role.title for role in roles)
        selector = {
          targetName  : 'JAccount'
          sourceId    : @getId()
          as          : { $in: roleTitles }
        }
        selector.targetId = $in: ids  if ids
        Relationship.someData selector, {as:1, targetId:1}, (err, cursor)->
          if err then callback err
          else
            cursor.toArray (err, arr)->
              if err then callback err
              else callback null, arr

  fetchUserStatus: permit 'grant permissions',
    success:(client, nicknames, callback)->
      JUser    = require '../user'
      JUser.someData username: $in: nicknames, {status:1, username:1}, (err, cursor) ->
        return callback err  if err
        cursor.toArray callback

  fetchMembers$: permit 'list members',
    success:(client, rest...)->
      # when max limit is over 20 it starts giving "call stack exceeded" error
      [selector, options, callback] = Module.limitEdges 10, 19, rest
      # delete options.targetOptions
      options.client = client
      @fetchMembers selector, options, callback

  # this method contains copy/pasted code from jAccount.findSuggestions method.
  # It is a workaround, and will be changed after elasticsearch implementation. CtF
  searchMembers: permit 'list members',
    success: (client, seed, options = {}, callback) ->
      cleanSeed = seed.replace(/[^\w\s-]/).trim()
      seed = RegExp cleanSeed, "i"

      names = seed.toString().split('/')[1].replace('^','').split ' '
      names.push names.first  if names.length is 1

      selector =
        $or : [
            ( 'profile.nickname'  : seed )
            ( 'profile.firstName' : new RegExp '^'+names.slice(0, -1).join(' '), 'i' )
            ( 'profile.lastName'  : new RegExp '^'+names.last, 'i' )
          ]
        type    :
          $in   : ['registered', null]
          # CtF null does not effect the results here, it only searches for registered ones.
          # probably jraphical problem, because the query correctly works in mongo

      {limit, skip} = options
      options.sort  = 'meta.createdAt' : -1
      options.limit = Math.min limit ? 10, 15
      # CtF @fetchMembers first fetches all group-member relationships, and then filters accounts with found targetIds.
      # As a result searching groups with large number of members is very time consuming. For now the only group
      # with large member count is koding, so i have seperated it here. as a future work hopefully we will make
      # the search queries via elasticsearch.
      if @slug is "koding"
        JAccount = require '../account'
        JAccount.some selector, options, callback
      else
        options.targetOptions = {options, selector}

        @fetchMembers {}, options, callback

  fetchNewestMembers$: permit 'list members',
    success:(client, rest...)->
      [selector, options, callback] = Module.limitEdges 10, 19, rest
      selector            or= {}
      selector.as         = 'member'
      selector.sourceName = 'JGroup'
      selector.sourceId   = @getId()
      selector.targetName = 'JAccount'

      options             or= {}
      options.sort        or=
        timestamp         : -1
      options.limit       or= 16

      Relationship.some selector, options, (err,members)=>
        if err then callback err
        else
          targetIds = (member.targetId for member in members)
          JAccount = require '../account'
          JAccount.some
            _id   :
              $in : targetIds
          , {}, (err,memberAccounts)=>
            callback err,memberAccounts

  fetchHomepageView: (options, callback)->
    {account, section} = options
    kallback = =>
      @fetchMembershipPolicy (err, policy)=>
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
      @isMember account, (err, isMember)->
        return callback err if err
        if isMember then kallback()
        else do callback
    else
      kallback()


  fetchRolesByClientId:(clientId, callback)->
    [callback, clientId] = [clientId, callback]  unless callback
    return callback null, []  unless clientId

    JSession = require '../session'
    JSession.one {clientId}, (err, session)=>
      return callback err  if err
      {username} = session.data
      return callback null, []  unless username

      @fetchMembershipStatusesByUsername username, (err, roles)=>
        callback err, roles or [], session

  createRole: permit 'grant permissions',
    success:(client, formData, callback)->
      JGroupRole = require './role'
      JGroupRole.create
        title           : formData.title
        isConfigureable : formData.isConfigureable or no
      , callback

  addCustomRole: permit 'grant permissions',
    success:(client,formData,callback)->
      @createRole client,formData, (err,role)=>
        console.log err,role
        unless err
          @addRole role, callback
        else
          callback err, null

  createMembershipPolicy:(requestType, queue, callback)->
    [callback, queue] = [queue, callback]  unless callback
    queue ?= []

    JMembershipPolicy = require './membershippolicy'
    membershipPolicy  = new JMembershipPolicy
    membershipPolicy.approvalEnabled = no  if requestType is 'by-invite'

    queue.push(
      -> membershipPolicy.save (err)->
        if err then callback err
        else queue.next()
      => @addMembershipPolicy membershipPolicy, (err)->
        if err then callback err
        else queue.next()
    )
    queue.push callback  if callback
    daisy queue

  destroyMemebershipPolicy:(callback)->
    @fetchMembershipPolicy (err, policy)->
      if err then callback err
      else unless policy?
        callback new KodingError '404 Membership policy not found'
      else policy.remove callback

  convertPublicToPrivate =(group, callback=->)->
    group.createMembershipPolicy callback

  convertPrivateToPublic =(group, client, callback=->)->
    kallback = (err)->
      return callback err if err
      queue.next()

    daisy queue = [
      -> group.resolvePendingRequests client, kallback
      -> group.destroyMemebershipPolicy kallback
      -> callback null
    ]

  setPrivacy:(privacy, client)->
    if @privacy is 'public' and privacy is 'private'
      convertPublicToPrivate this
    else if @privacy is 'private' and privacy is 'public'
      convertPrivateToPublic this, client
    @privacy = privacy

  getPrivacy:-> @privacy

  modify: permit
    advanced : [
      { permission: 'edit own groups', validateWith: Validators.own }
      { permission: 'edit groups' }
    ]
    success : (client, formData, callback)->
      # do not allow people to change there slugs
      delete formData.slug
      delete formData.slug_
      @setPrivacy formData.privacy, client
      @update {$set:formData}, callback

  modifyMembershipPolicy: permit
    advanced: PERMISSION_EDIT_GROUPS
    success: (client, formData, callback)->
      @fetchMembershipPolicy (err, policy)->
        if err then callback err
        else policy.update $set: formData, callback

  canEditGroup: permit 'grant permissions'

  @canReadGroupActivity = permit 'read group activity'
  canReadGroupActivity  : permit 'read group activity'
  @canListMembers       = permit 'list members'

  canOpenGroup: permit 'open group',
    failure:(client, callback)->
      @fetchMembershipPolicy (err, policy)->
        explanation = policy?.explain() ?
                      err?.message ?
                      'No membership policy!'
        clientError = err ? new KodingError explanation
        clientError.accessCode = policy?.code ?
          if err then ERROR_UNKNOWN
          else if explanation? then ERROR_POLICY
          else ERROR_NO_POLICY
        callback clientError, no

  resolvePendingRequests: permit 'send invitations',
    success: (client, callback)->
      @fetchMembershipPolicy (err, policy)=>
        if err then callback err
        else unless policy then callback new KodingError 'No membership policy!'
        else
          selector =
            group          : @slug
            status         : 'pending'
          JInvitationRequest = require '../invitationrequest'
          JInvitationRequest.each selector, {}, (err, request)->
            if err then callback err
            else if request? then request.approve client
            else callback null

  fetchAccountByEmail: (email, callback) ->
    JUser    = require '../user'
    JUser.one {email}, (err, user)=>
      return callback err, null  if err or not user
      user.fetchOwnAccount (err, account)=>
        return callback err, null  if err
        return callback new Error "Account not found.", null  unless account
        @isMember account, (err, isMember)->
          if isMember
            callback new KodingError "#{email} is already member of this group!"
          else
            callback null, account

  inviteByEmail: do=>
    permit 'send invitations',
      success: (client, email, options, callback)->
        @fetchAccountByEmail email, (err, account)=>
          return callback err  if err
          @inviteMember client, email, account, options, callback

  inviteByEmails: permit 'send invitations',
    success: (client, emails, options, callback)->
      {uniq} = require 'underscore'
      errors = []
      queue = uniq(emails.split(/\n/)).map (email)=>=>
        @inviteByEmail client, email.trim(), options, (err)->
          errors.push err  if err
          queue.next()
      queue.push -> callback if errors.length > 0 then errors else null
      daisy queue

  saveInviteMessage: permit 'send invitations',
    success: (client, messageType, message, callback=->)->
      @fetchMembershipPolicy (err, policy)=>
        return callback err  if err
        set = {}
        set["communications.#{messageType}"] = message
        policy.update $set: set, callback

  inviteMember : permit 'send invitations',
    success: (client, email, account, options, callback)->
      JInvitation = require '../invitation'
      JInvitation.create client, @slug, email, options, (err, invite)=>
        return callback err  if err
        @addInvitation invite, (err)=>
          return callback err  if err
          invite.sendMail client, this, options, (err)->
            return callback err  if err
            kallback = (err)-> callback err, invite

            JAccount = require '../account'
            if account instanceof JAccount
              account.emit 'NewPendingInvitation'
              account.addInvitation invite, kallback
            else
              kallback null

  isMember: (account, callback)->
    return callback new Error "No account found!"  unless account
    selector =
      sourceId  : @getId()
      targetId  : account.getId()
      as        : 'member'
    Relationship.count selector, (err, count)->
      if err then callback err
      else callback null, (if count is 0 then no else yes)

  redeemInvitation: secure (client, code, callback)->
    {delegate} = client.connection
    @isMember delegate, (err, isMember)=>
      return callback err  if err or isMember
      selector = targetOptions: selector: {code, status:$in:['active', 'sent']}
      @fetchInvitations {}, selector, (err, [invite])=>
        return callback err  if err
        return callback new KodingError 'Invitation code is invalid!'  unless invite
        delegate.fetchUser (err, user)=>
          return callback err  if err
          unless invite.type is 'multiuse' or user.email is invite.email
            return callback new KodingError 'Are you sure invitation e-mail is for you?'

          invite.redeem delegate, (err) =>
            return callback err if err
            @approveMember delegate, callback

  bulkApprove: permit 'send invitations',
    success: (client, count, options, callback)->
      selOptions =
        targetOptions: {selector: status: 'pending'},
        limit: count,
        sort: requestedAt: 1
      @fetchInvitationRequests {}, selOptions, (err, requests)->
        return callback err  if err
        errors = []
        emails = []
        queue = requests.map (request)-> ->
          request.approve client, options, (err)->
            if err
              errors.push "#{request.email} failed!"
            else
              emails.push request.email
            setTimeout queue.next.bind(queue), 50
        queue.push -> callback (if errors.length > 0 then errors else null), emails
        daisy queue

  requestAccess: secure (client, callback)->
    @requestAccessFor client, callback

  requestAccessFor: (account, callback)->
    JInvitationRequest = require '../invitationrequest'
    JUser              = require '../user'
    JAccount           = require '../account'

    account = account.connection.delegate  if account.connection?

    @fetchMembershipPolicy (err, policy)=>
      return callback err  if err
      account.fetchUser (err, user)=>
        return callback err  if err

        if policy?.approvalEnabled
          invitationType = 'basic approval'
        else
          invitationType = 'invitation'

        selector = {
          invitationType
          group  : @slug
          email  : user.email
          status : $not: $in: JInvitationRequest.resolvedStatuses
        }

        JInvitationRequest.one selector, (err, invitationRequest)=>
          return callback err, invitationRequest  if err or invitationRequest
          selector.status   = 'pending'
          selector.username = user.username

          invitationRequest = new JInvitationRequest selector
          invitationRequest.save (err)=>
            return callback err  if err
            @addInvitationRequest invitationRequest, (err)=>
              return callback err if err
              @emit 'NewInvitationRequest'

              unless @slug is 'koding' # comment out to test with koding group
                invitationRequest.sendRequestNotification(
                  this, account, user.email, invitationType
                )

              account.addInvitationRequest invitationRequest, callback

  approveMember:(member, roles, callback)->
    [callback, roles] = [roles, callback]  unless callback
    roles ?= ['member']

    kallback = =>
      callback()
      @updateCounts()
      @emit 'MemberAdded', member  if 'member' in roles

    queue = roles.map (role)=>=>
      @addMember member, role, queue.fin.bind queue

    dash queue, =>
      if @slug not in ["koding", "guests"]
      then @createMemberVm member, kallback
      else kallback()

  each:(selector, rest...)->
    selector.visibility = 'visible'
    Module::each.call this, selector, rest...

  fetchVocabulary$: permit 'administer vocabularies',
    success:(client, rest...)-> @fetchVocabulary rest...

  fetchRolesHelper: (account, callback)->
    client = connection: delegate : account
    @fetchMyRoles client, (err, roles)=>
      if err then callback err
      else if 'member' in roles or 'admin' in roles
        callback null, roles
      else
        options = targetOptions:
          selector: { koding: username: account.profile.nickname }
        @fetchInvitationRequest {}, options, (err, request)->
          if err then callback err
          else unless request? then callback null, ['guest']
          else callback null, ["invitation-#{request.status}"]

  fetchMembershipStatusesByUsername: (username, callback)->
    JAccount = require '../account'
    JAccount.one {'profile.nickname': username}, (err, account)=>
      if not err and account
        @fetchRolesHelper account, callback
      else
        console.error err
        callback err

  fetchMembershipStatuses: secure (client, callback)->
    JAccount = require '../account'
    {delegate} = client.connection
    unless delegate instanceof JAccount
      callback null, ['guest']
    else
      @fetchRolesHelper delegate, callback

  updateCounts:->
    # remove this guest shit if required
    if @getId().toString() is "51f41f195f07655e560001c1"
      return

    Relationship.count
      as         : 'member'
      targetName : 'JAccount'
      sourceId   : @getId()
      sourceName : 'JGroup'
    , (err, count)=>
      @update ($set: 'counts.members': count), ->

  leave: secure (client, options, callback)->

    [callback, options] = [options, callback] unless callback

    if @slug in ['koding', 'guests']
      return callback new KodingError "It's not allowed to leave this group"

    @fetchMyRoles client, (err, roles)=>
      return callback err if err

      if 'owner' in roles
        return callback new KodingError 'As owner of this group, you must first transfer ownership to someone else!'

      Joinable = require '../../traits/joinable'

      kallback = (err)=>
        @updateCounts()
        @cycleChannel()
        callback err

      queue = roles.map (role)=>=>
        Joinable::leave.call this, client, {as:role}, (err)->
          return kallback err if err
          queue.fin()

      dash queue, kallback

  kickMember: permit 'grant permissions',
    success: (client, accountId, callback)->
      {connection:{delegate}} = client
      JAccount = require '../account'

      if @slug is 'koding'
        return callback new KodingError 'Koding group is mandatory'

      JAccount.one _id:accountId, (err, account)=>
        return callback err if err

        if client.connection.delegate.getId().equals account._id
          return callback new KodingError 'You cannot kick yourself, try leaving the group!'

        @fetchRolesByAccount account, (err, roles)=>
          return callback err if err

          if 'owner' in roles
            return callback new KodingError 'You cannot kick the owner of the group!'

          kallback = (err) =>

          queue = roles.map (role)=>=>
            @removeMember account, role, (err)=>
              return callback err  if err
              @updateCounts()
              @cycleChannel()
              queue.fin()

          queue.push =>
            JVM = require "../vm"
            selector = groups: $elemMatch: id: @getId()
            JVM.fetchAccountVmsBySelector account, selector, (err, hostnameAliases) =>
              return callback err  if err
              JVM.some hostnameAlias: $in: hostnameAliases, null, (err, vms) =>
                return callback err  if err
                vmSuspendQueue = vms.map (vm) ->
                  ->
                    vm.suspend (err) ->
                      console.warn "VM couldn't be suspended #{vm.hostnameAlias}", err  if err
                      vmSuspendQueue.fin()

                dash vmSuspendQueue, =>
                  @creditPack tag: "vm", multiplyFactor: vms.length, (err) ->
                    console.warn "VM pack couldn't be credited for group #{@slug}", err  if err
                    queue.fin()

          dash queue, callback

  transferOwnership: permit 'grant permissions',
    success: (client, accountId, callback)->
      JAccount = require '../account'

      {delegate} = client.connection
      if delegate.getId().equals accountId
        return callback new KodingError 'You cannot transfer ownership to yourself, concentrate and try again!'

      Relationship.one {
        targetId: delegate.getId(),
        sourceId: @getId(),
        as      : 'owner'
      }, (err, owner)=>
        return callback err if err
        return callback new KodingError 'You must be the owner to perform this action!' unless owner

        JAccount.one _id:accountId, (err, account)=>
          return callback err if err

          @fetchRolesByAccount account, (err, newOwnersRoles)=>
            return callback err if err

            kallback = (err)=>
              @cycleChannel()
              @updateCounts()
              callback err

            # give rights to new owner
            queue = difference(['member', 'admin'], newOwnersRoles).map (role)=>=>
              @addMember account, role, (err)->
                return kallback err if err
                queue.fin()

            dash queue, =>
              # transfer ownership
              owner.update $set: targetId: account.getId(), kallback

  ensureUniquenessOfRoleRelationship:(target, options, fallbackRole, roleUnique, callback)->
    unless callback
      callback   = roleUnique
      roleUnique = no

    if 'string' is typeof options
      as = options
    else if options?.as
      {as} = options
    else
      as = fallbackRole

    # remove this
    if @getId().toString() is "51f41f195f07655e560001c1"
      return callback null

    selector =
      targetName : target.bongo_.constructorName
      sourceId   : @getId()
      sourceName : @bongo_.constructorName
      as         : as

    unless roleUnique
      selector.targetId = target.getId()

    Relationship.count selector, (err, count)->
      if err then callback err
      else if count > 0 then callback new KodingError 'This relationship already exists'
      else callback null

  oldAddMember = @::addMember
  addMember:(target, options, callback)->
    @ensureUniquenessOfRoleRelationship target, options, 'member', (err)=>
      if err then callback err
      else oldAddMember.call this, target, options, callback

  oldAddAdmin = @::addAdmin
  addAdmin:(target, options, callback)->
    @ensureUniquenessOfRoleRelationship target, options, 'admin', (err)=>
      if err then callback err
      else oldAddAdmin.call this, target, options, callback

  oldAddOwner = @::addOwner
  addOwner:(target, options, callback)->
    @ensureUniquenessOfRoleRelationship target, options, 'owner', yes, (err)=>
      if err then callback err
      else oldAddOwner.call this, target, options, callback

  remove_ = @::remove
  remove: secure (client, callback)->
    JName = require '../name'
    JNewStatusUpdate = require '../messages/newstatusupdate'

    @fetchOwner (err, owner)=>
      return callback err if err
      unless owner.getId().equals client.connection.delegate.getId()
        return callback new KodingError 'You must be the owner to perform this action!'

      removeHelper = (model, err, callback, queue)->
        return callback err if err
        return queue.next() unless model
        model.remove (err)=>
          return callback err if err
          queue.next()

      removeHelperMany = (klass, models, err, callback, queue)->
        return callback err if err
        return queue.next() if not models or models.length < 1
        ids = (model._id for model in models)
        klass.remove (_id: $in: ids), (err)->
          return callback err if err
          queue.next()

      daisy queue = [
        => JName.one name:@slug, (err, name)->
          removeHelper name, err, callback, queue

        => @fetchPermissionSet (err, permSet)->
          removeHelper permSet, err, callback, queue

        => @fetchDefaultPermissionSet (err, permSet)->
          removeHelper permSet, err, callback, queue

        => @fetchMembershipPolicy (err, policy)->
          removeHelper policy, err, callback, queue

        => @fetchInvitationRequests (err, requests)->
          JInvitationRequest = require '../invitationrequest'
          removeHelperMany JInvitationRequest, requests, err, callback, queue

        => @fetchInvitations (err, requests)->
          JInvitation = require '../invitation'
          removeHelperMany JInvitation, requests, err, callback, queue

        => @fetchTags (err, tags)->
          JTag = require '../tag'
          removeHelperMany JTag, tags, err, callback, queue

        => @fetchApplications (err, apps)->
          JNewApp = require '../app'
          removeHelperMany JNewApp, apps, err, callback, queue

        => JNewStatusUpdate.count group:@slug, (err, count)=>
          numberOfNamePages = Math.ceil(count / 50)

          deleteQueue = [1..numberOfNamePages].map (pageNumber)=>=>
            skip = (pageNumber - 1) * 50
            option = {
              limit : 50,
              skip  : skip
            }
            JNewStatusUpdate.some group:@slug, option, (err, statusUpdates)=>
              removeHelperMany JNewStatusUpdate, statusUpdates, err, callback, deleteQueue

          deleteQueue.push => queue.next()
          daisy deleteQueue

        =>
          @constructor.emit 'GroupDestroyed', this
          queue.next()

        => remove_.call this, (err)->
          return callback err if err
          queue.next()

        -> callback null
      ]

  sendNotificationToAdmins: (event, contents)->
    @fetchAdmins (err, admins)=>
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
        contents.actorType    = event
        contents[event]       = contents.member

        next = -> queue.next()
        queue = admins.map (admin) =>=>
          contents.recipient = admin
          @notify admin, event, contents, next

        daisy queue

  # addProduct: permit 'manage products',
  #   success: (client, data, callback)->
  #     JPaymentGroup = require '../payment/group'
  #     JPaymentGroup.addPlan this, data, callback

  # deleteProduct: permit 'manage products',
  #   success: (client, data, callback)->
  #     JPaymentGroup = require '../payment/group'
  #     JPaymentGroup.deletePlan this, data, callback

  checkVmType: (data, callback) ->
    unless data.type in ['user', 'group', 'expensed']
      callback new KodingError "No such VM type: #{data.type}"
    else
      callback null

  fetchOrCreateBundle: (callback) ->
    @fetchBundle (err, bundle) =>
      return callback err, bundle  if err or bundle

      if @slug is 'koding'
        @createBundle
          overagePolicy: 'not allowed'
          paymentPlan  : ''
          allocation   : 0
          sharedVM     : yes
        , (err, bundle) =>
          if err then return callback new KodingError 'Unable to create default group bundle'
          callback null, bundle
      else
        callback new KodingError 'Unable to fetch group bundle'

  countMembers: secure (client, callback)->
    {Member} = require "../graph"
    Member.fetchMemberCount {groupId:@_id, client:client}, callback

  fetchOrCountInvitations: permit 'send invitations',
    success: (client, type, method, options, callback)->
      supportedTypes = ['Invitation', 'InvitationRequest', 'InvitationCode']
      return callback 'unsupported type'  unless type in supportedTypes

      options.groupId = @getId()
      {Invitation} = require "../graph"
      Invitation["fetchOrCount#{type}s"] method, options, callback

  fetchInvitationsByStatus: permit 'send invitations',
    success: (client, options, callback)->
      JInvitation = require '../invitation'
      if options.type is "InvitationCode"
        type   = "multiuse"
        status = if options.showResolved then ["active" , "redeemed"] else ['active']
      else
        type   = "admin"
        status = if options.showResolved then ["sent", "redeemed"] else ["sent"]

      JInvitation.some
        group  : @slug
        type   : type
        status :
          $in  : status
        , options
        , callback

  fetchInvitationsFromGraph: permit 'send invitations',
    success: (client, type, options, callback)->
      @fetchOrCountInvitations client, type, 'fetch', options, (err, results)=>
        return callback err  if err
        ids = (res.groupOwnedNodes.data.id  for res in results)

        require(
          if type is 'InvitationRequest'
          then '../invitationrequest'
          else '../invitation'
        ).some _id: $in: ids, {}, callback

  countInvitationsFromGraph: permit 'send invitations',
    success: (client, type, options, callback)->
      @fetchOrCountInvitations client, type, 'count', options, (err, result)=>
        return callback err, result?[0]?.count

  fetchMembersFromGraph:(client, options, callback)->
    options.groupId = @getId()
    options.client  = client
    {Member} = require '../graph'
    Member.fetchMemberList options, (err, results)=>
      callback err, results

  fetchMembersFromGraph$: permit 'list members',
    success: (client, rest...) -> @fetchMembersFromGraph client, rest...

  @each$ = (selector, options, callback)->
    selector.visibility = 'visible'
    @each selector, options, callback

  linkPaymentMethod: permit 'manage payment methods',
    success: (client, paymentMethodId, callback) ->
      { delegate } = client.connection
      JPaymentMethod = require '../payment/method'
      JPaymentMethod.one { paymentMethodId }, (err, paymentMethod) =>
        return callback err  if err
        delegate.hasTarget paymentMethod, 'payment method', (err, hasTarget) =>
          return callback err  if err
          return callback { message: 'Access denied!' }  unless hasTarget
          @addPaymentMethod paymentMethod, callback

  unlinkPaymentMethod: permit 'manage payment methods',
    success: (client, paymentMethodId, callback) ->
      JPaymentMethod = require '../payment/method'
      JPaymentMethod.one { paymentMethodId }, (err, paymentMethod) =>
        return callback err  if err
        @removePaymentMethod paymentMethod, callback

  fetchPaymentMethod$: permit 'manage payment methods',
    success: (client, callback) ->
      JPaymentMethod = require '../payment/method'
      @fetchPaymentMethod (err, paymentMethod) ->
        return callback err  if err
        JPaymentMethod.decoratePaymentMethods [paymentMethod], (err, paymentMethods) ->
          return callback err  if err
          callback null, paymentMethods[0]

  fetchProducts$: (category, options, callback) ->
    [options, callback] = [callback, options]  unless callback
    options ?= {}
    { tag, tags } = options
    tags = [tag]  if tag and not tags

    options.targetOptions ?= {}
    options.targetOptions.options ?= {}
    options.targetOptions.options.sort ?= sortWeight: 1
    options.targetOptions.selector =
      if tags
      then { tags }
      else {}

    switch category
      when 'product'
        @fetchProducts {}, options, callback
      when 'pack'
        @fetchPacks {}, options, callback
      when 'plan'
        @fetchPlans {}, options, callback

  addSubscription$: permit 'edit own groups',
    success: (client, id, callback) ->
      JPaymentSubscription = require '../payment/subscription'
      JPaymentSubscription.one _id: id, (err, subscription) =>
        @addSubscription subscription, callback

  fetchSubscription$: secure (client, callback) ->
    @fetchSubscription (err, subscription) ->
      return callback err  if err
      {planCode} = subscription
      JPaymentPlan = require '../payment/plan'
      JPaymentPlan.one {planCode}, (err, plan) ->
        return callback err  if err
        subscription.plan = plan
        callback null, subscription

  fetchPermissionSetOrDefault : (callback)->
    @fetchPermissionSet (err, permissionSet) =>
      callback err, null if err
      if permissionSet
        callback null, permissionSet
      else
        @fetchDefaultPermissionSet callback

  _fetchSubscription: (callback) ->
    @fetchSubscription (err, subscription) =>
      return callback new KodingError "Error when fetching group's subscription: #{err}"  if err
      return callback new KodingError "Group #{@slug}'s subscription is not found"  unless subscription
      callback err, subscription

  debitPack: (options, callback) ->
    @_fetchSubscription (err, subscription) ->
      return callback err  if err
      subscription.debitPack options, callback

  creditPack: (options, callback) ->
    @_fetchSubscription (err, subscription) ->
      return callback err  if err
      subscription.creditPack options, callback

  createMemberVm: (account, callback) ->
    @debitPack tag: "vm", (err) =>
      return callback err  if err
      JVM = require '../vm'
      JVM.createVm {account, groupSlug: @slug, @planCode}, (err) =>
        console.warn "Group #{@slug} member #{account.profile.nickname} VM is not created: #{err}"  if err
        callback()

  createSocialApiChannelId: (callback) ->
    # disable for now
    # return callback null, @socialApiChannelId  if @socialApiChannelId
    @fetchOwner (err, owner)=>
      return callback err if err
      unless owner
        return callback { message: "Owner not found for #{@slug} group" }
      owner.createSocialApiId (err, socialApiId)=>
        return callback err if err
        # required data for creating a channel
        data =
          name         : @slug
          creatorId    : socialApiId
          group        : @slug
          typeConstant : "group"

        {createChannel} = require '../socialapi/requests'
        createChannel data, (err, socialApiChannel)=>
          return callback err if err
          @update $set: socialApiChannelId: socialApiChannel.id, (err)->
            return callback err if err
            return callback null, socialApiChannel.id
