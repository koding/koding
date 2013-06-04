{Module} = require 'jraphical'
{difference} = require 'underscore'

module.exports = class JGroup extends Module


  [ERROR_UNKNOWN, ERROR_NO_POLICY, ERROR_POLICY] = [403010, 403001, 403009]

  {Relationship} = require 'jraphical'

  {Inflector, ObjectId, ObjectRef, secure, daisy, dash} = require 'bongo'

  JPermissionSet = require './permissionset'
  {permit} = JPermissionSet

  KodingError = require '../../error'

  Validators = require './validators'

  {throttle} = require 'underscore'

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
      'list members'                      : ['guest','member','moderator']
      'create groups'                     : ['moderator']
      'edit groups'                       : ['moderator']
      'edit own groups'                   : ['member','moderator']
      'query collection'                  : ['member','moderator']
      'update collection'                 : ['moderator']
      'assure collection'                 : ['moderator']
      'remove documents from collection'  : ['moderator']
      'view readme'                       : ['guest','member','moderator']
    indexes         :
      slug          : 'unique'
    sharedEvents    :
      static        : [
        { name: 'MemberAdded',      filter: -> null }
        { name: 'MemberRemoved',    filter: -> null }
        { name: 'MemberRolesChanged' }
        { name: 'GroupDestroyed' }
        { name: 'broadcast' }
      ]
      instance      : [
        { name: 'GroupCreated' }
        { name: 'MemberAdded',      filter: -> null }
        { name: 'MemberRemoved',    filter: -> null }
        { name: 'NewInvitationRequest' }
      ]
    sharedMethods   :
      static        : [
        'one','create','each','count','byRelevance','someWithRelationship'
        '__resetAllGroups','fetchMyMemberships','__importKodingMembers',
        'suggestUniqueSlug'
      ]
      instance      : [
        'join', 'leave', 'modify', 'fetchPermissions', 'createRole'
        'updatePermissions', 'fetchMembers', 'fetchRoles', 'fetchMyRoles'
        'fetchUserRoles','changeMemberRoles','canOpenGroup', 'canEditGroup'
        'fetchMembershipPolicy','modifyMembershipPolicy','requestAccess'
        'fetchReadme', 'setReadme', 'addCustomRole', 'fetchInvitationRequests'
        'countPendingInvitationRequests', 'countPendingSentInvitations',
        'countInvitationRequests', 'fetchInvitationRequestCounts',
        'resolvePendingRequests','fetchVocabulary', 'fetchMembershipStatuses',
        'setBackgroundImage', 'removeBackgroundImage', 'fetchAdmin', 'inviteByEmail',
        'inviteByEmails', 'inviteByUsername', 'kickMember', 'transferOwnership',
        'fetchBundle', 'createBundle', 'destroyBundle', 'updateBundle', 'fetchRolesByClientId',
        'remove', 'sendSomeInvitations', 'fetchNewestMembers', 'countMembers'
      ]
    schema          :
      title         :
        type        : String
        required    : yes
      body          : String
      avatar        : String
      slug          :
        type        : String
        validate    : require('../name').validateName
        set         : (value)-> value.toLowerCase()
      privacy       :
        type        : String
        enum        : ['invalid privacy type', ['public', 'private']]
      visibility    :
        type        : String
        enum        : ['invalid visibility type', ['visible', 'hidden']]
      parent        : ObjectRef
      counts        :
        members     : Number
      customize     :
        background  :
          customImages    : [String]
          customColors    : [String]
          customType      :
            type          : String
            default       : 'defaultImage'
            enum          : ['Invalid type', [ 'defaultImage', 'customImage', 'defaultColor', 'customColor']]
          customValue     :
            type          : String
            default       : '1'
          customOptions   : Object
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
        targetType  : 'JApp'
        as          : 'owner'
      vocabulary    :
        targetType  : 'JVocabulary'
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
      readme        :
        targetType  : 'JMarkdownDoc'
        as          : 'owner'
      vm            :
        targetType  : 'JVM'
        as          : 'owner'
      paymentPlan   : 
        targetType  : 'JRecurlyPlan'
        as          : 'owner'

  constructor:->
    super

    @on 'MemberAdded', (member)->
      @constructor.emit 'MemberAdded', { group: this, member }
      @sendNotificationToAdmins 'GroupJoined',
        actionType : 'groupJoined'
        actorType  : 'member'
        subject    : ObjectRef(this).data
        member     : ObjectRef(member).data

    @on 'MemberRemoved', (member)->
      @constructor.emit 'MemberRemoved', { group: this, member }

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

  setBackgroundImage: permit 'edit groups',
    success:(client, type, value, callback=->)->
      if type is 'customImage'
        operation =
          $set: {}
          $addToSet : {}
        operation.$addToSet['customize.background.customImages'] = value
      else if type is 'customColor'
        operation =
          $set: {}
          $addToSet : {}
        operation.$addToSet['customize.background.customColors'] = value
      else
        operation = $set : {}

      operation.$set["customize.background.customType"] = type

      if type in ['defaultImage','defaultColor','customColor','customImage']
        operation.$set["customize.background.customValue"] = value

      @update operation, callback

  removeBackgroundImage: permit 'edit groups',
    success:(client, type, value, callback=->)->
      if type is 'customImage'
        @update {$pullAll: 'customize.background.customImages': [value]}, callback
      else if type is 'customColor'
        @update {$pullAll: 'customize.background.customColors': [value]}, callback
      else
        console.log 'Nothing to remove'

  @renderHomepage: require './render-homepage'

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

    create = (groupData, owner, callback) ->
      JPermissionSet        = require './permissionset'
      JMembershipPolicy     = require './membershippolicy'
      JName                 = require '../name'
      group                 = new this groupData
      permissionSet         = new JPermissionSet
      defaultPermissionSet  = new JPermissionSet
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
             JName.release group.slug, => callback err
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
        -> save_ 'permission set', permissionSet, queue, callback
        -> save_ 'default permission set', defaultPermissionSet, queue,
                  callback
        -> group.addPermissionSet permissionSet, (err)->
            if err then callback err
            else
              console.log 'permissionSet is added'
              queue.next()
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

      if groupData.paymentPlan
        queue.push -> group.addPaymentPlan groupData.paymentPlan, (err)->
            if err then callback err
            else
              console.log 'payment plan is added'
              queue.next()

      if groupData['group-vm'] is 'on'
        limits =
          users           : { quota: 100 }
          cpu             : { quota: 100 }
          ram             : { quota: 100 }
          disk            : { quota: 100 }
          'cpu per user'  : { quota: 100 }
          'ram per user'  : { quota: 100 }
          'disk per user' : { quota: 100 }
        queue.push -> group.createBundle limits, (err)->
          if err then callback err
          else
            console.log 'group bundle created'
            queue.next()

      queue.push =>
        @emit 'GroupCreated', { group, creator: owner }
        callback null, group

      daisy queue

  @create$ = secure (client, formData, callback)->
    JAccount = require '../account'
    {delegate} = client.connection

    unless delegate instanceof JAccount
      return callback new KodingError 'Access denied.'

    @create formData, delegate, callback

  @findSuggestions = (client, seed, options, callback)->
    {limit, blacklist, skip}  = options

    @some {
      title   : seed
      _id     :
        $nin  : blacklist
      visibility: 'visible'
    },{
      skip
      limit
      sort    : 'title' : 1
    }, callback

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

  broadcast:(message)-> @constructor.broadcast @slug, message

  changeMemberRoles: permit 'grant permissions',
    success:(client, memberId, roles, callback)->
      group = this
      groupId = @getId()
      roles.push 'member'  unless 'member' in roles
      oldRole =
        targetId    : memberId
        sourceId    : groupId
      Relationship.remove oldRole, (err)->
        if err then callback err
        else
          queue = roles.map (role)->->
            (new Relationship
              targetName  : 'JAccount'
              targetId    : memberId
              sourceName  : 'JGroup'
              sourceId    : groupId
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
        if err
          callback err
        else if permissionSet?
          permissionSet.update $set:{permissions}, callback
        else
          permissionSet = new JPermissionSet {permissions}
          permissionSet.save callback

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

  fetchMembers$: permit 'list members',
    success:(client, rest...)->
      [selector, options, callback] = Module.limitEdges 100, rest
      @fetchMembers selector, options, callback

  fetchNewestMembers$: permit 'list members',
    success:(client, rest...)->
      [selector, options, callback] = Module.limitEdges 100, rest
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

  # fetchMyFollowees: permit 'list members'
  #   success:(client, options, callback)->
  #     [callback, options] = [options, callback]  unless callback
  #     options ?=


  # fetchMyFollowees: permit 'list members'
  #   success:(client, options, callback)->

  fetchReadme$: permit 'view readme',
    success:(client, rest...)-> @fetchReadme rest...

  setReadme$: permit
    advanced: PERMISSION_EDIT_GROUPS
    success:(client, text, callback)->
      @fetchReadme (err, readme)=>
        unless readme
          JMarkdownDoc = require '../markdowndoc'
          readme = new JMarkdownDoc content: text

          daisy queue = [
            ->
              readme.save (err)->
                console.log err
                if err then callback err
                else queue.next()
            =>
              @addReadme readme, (err)->
                console.log err
                if err then callback err
                else queue.next()
            ->
              callback null, readme
          ]

        else
          readme.update $set:{ content: text }, (err)=>
            if err then callback err
            else callback null, readme
    failure:(client,text, callback)->
      callback new KodingError "You are not allowed to change this."

  fetchHomepageView:(callback)->
    @fetchReadme (err, readme)=>
      return callback err  if err
      @fetchMembershipPolicy (err, policy)=>
        if err then callback err
        else
          callback null, JGroup.renderHomepage {
            @slug
            @title
            policy
            @avatar
            @body
            @counts
            content : readme?.html ? readme?.content
            @customize
          }

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
      -> group.resolvePendingRequests client, yes, kallback
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

  canReadActivity: permit 'read activity'

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

  countPendingInvitationRequests: permit 'send invitations',
    success: (client, callback)->
      @countInvitationRequests {}, {status: 'pending'}, callback

  countPendingSentInvitations: permit 'send invitations',
    success: (client, callback)->
      @countInvitationRequests {}, {status: 'sent'}, callback

  countInvitationRequests$: permit 'send invitations',
    success: (client, rest...)-> @countInvitationRequests rest...

  fetchInvitationRequestCounts: permit 'send invitations',
    success: ->
      switch arguments.length
        when 2
          [client, callback] = arguments
          types = ['invitation', 'basic approval']
        when 3
          [client, types, callback] = arguments
      counts = {}
      queue = types.map (invitationType)=>=>
        @countInvitationRequests {}, {invitationType}, (err, count)->
          if err then queue.fin err
          else
            counts[invitationType] = count
            queue.fin()
      dash queue, callback.bind null, null, counts

  resolvePendingRequests: permit 'send invitations',
    success: (client, isApproved, callback)->
      @fetchMembershipPolicy (err, policy)=>
        if err then callback err
        else unless policy then callback new KodingError 'No membership policy!'
        else
          invitationType =
            if policy.invitationsEnabled then 'invitation' else 'basic approval'

          method =
            if 'invitation' is invitationType
              if isApproved then 'send' else 'delete'
            else
              if isApproved then 'approve' else 'decline'

          invitationRequestSelector =
            group             : @slug
            status            : 'pending'
            invitationType    : invitationType
          JInvitationRequest = require '../invitationrequest'
          JInvitationRequest.each invitationRequestSelector, {}, (err, request)->
            if err then callback err
            else if request? then request[method+'Invitation'] client, callback
            else callback null

  inviteByEmail: permit 'send invitations',
    success: (client, email, callback)->
      @inviteMember client, email, callback

  inviteByEmails: permit 'send invitations',
    success: (client, emails, callback)->
      {uniq} = require 'underscore'
      errors = []
      queue = uniq(emails.split(/\n/)).map (email)=>=>
        @inviteByEmail client, email.trim(), (err)->
          errors.push err  if err
          queue.next()
      queue.push -> callback if errors.length > 0 then errors else null
      daisy queue

  inviteByUsername: permit 'send invitations',
    success: (client, usernames, callback)->
      JUser    = require '../user'
      usernames = [usernames] unless Array.isArray usernames
      queue = usernames.map (username)=>=>
        JUser.one {username}, (err, user)=>
          return callback err if err
          return callback new KodingError 'User does not exist!' unless user
          user.fetchOwnAccount (err, account)=>
            return callback err if err
            @isMember account, (err, isMember)=>
              return callback err if err
              return callback new KodingError "#{username} is already member of this group!" if isMember
              @inviteMember client, user.email, (err)->
                return queue.next() unless err
                replaceEmail = (errMsg)-> errMsg.replace user.email, username
                if err.name is 'KodingError' then err.message = replaceEmail err.message
                else err = replaceEmail err
                callback err
      queue.push -> callback null
      daisy queue

  inviteMember: (client, email, callback)->
    JInvitationRequest = require '../invitationrequest'

    params =
      email  : email
      group  : @slug
      status : $not: $in: JInvitationRequest.resolvedStatuses

    JInvitationRequest.one params, (err, invitationRequest)=>
      if invitationRequest
        callback new KodingError """
          You've already invited #{email}.
          """
      else
        params.invitationType = 'invitation'
        params.status         = 'sent'

        invitationRequest = new JInvitationRequest params
        invitationRequest.save (err)=>
          if err then callback err
          else @addInvitationRequest invitationRequest, (err)->
            if err then callback err
            else invitationRequest.sendInvitation client, callback

  isMember: (account, callback)->
    selector =
      sourceId  : @getId()
      targetId  : account.getId()
      as        : 'member'
    Relationship.count selector, (err, count)->
      if err then callback err
      else callback null, (if count is 0 then no else yes)

  fetchInvitationRequests$: permit 'send invitations',
    success: (client, rest...)-> @fetchInvitationRequests rest...

  sendSomeInvitations: permit 'send invitations',
    success: (client, count, callback)->
      @fetchInvitationRequests {}, {
        targetOptions :
          selector    : { status  : 'pending' }
          options     : { limit   : count }
      }, (err, requests)->
        if err then callback err
        else
          queue = requests.map (request)->->
            request.approveInvitation client, (err)->
              return callback err if err
              setTimeout queue.next.bind(queue), 50
          queue.push -> callback null
          daisy queue

  requestAccess: secure (client, formData, callback)->
    @requestAccessFor client, formData, callback

  requestAccessFor: (account, formData, callback)->
    JInvitationRequest = require '../invitationrequest'
    JUser              = require '../user'
    JAccount           = require '../account'

    [callback, formData] = [formData, callback]  unless callback
    formData ?= {}

    account = connection:delegate:account unless account.connection?
    {delegate} = account.connection

    @fetchMembershipPolicy (err, policy)=>
      if err then callback err
      else
        if policy?.approvalEnabled
          invitationType = 'basic approval'
        else
          invitationType = 'invitation'

        cb = (email, kallback)=>
          selector =
            group: @slug
            status: $not: $in: JInvitationRequest.resolvedStatuses

          if delegate instanceof JAccount
            selector['$or'] = [
              'koding.username' : delegate.profile.nickname
              {email}
            ]
          else
            selector.email = email

          JInvitationRequest.one selector, (err, invitationRequest)=>
            return kallback err if err
            # here we use callback instead of kallback as we simulate success here
            # but don't do any further actions
            if invitationRequest then callback null
            else
              invitationRequest = new JInvitationRequest {
                invitationType
                email   : email
                group   : @slug,
                status  : 'pending'
              }

              if delegate instanceof JAccount
                invitationRequest.koding = {}
                invitationRequest.koding.username = delegate.profile.nickname

              invitationRequest.save (err)=>
                return kallback err if err
                @addInvitationRequest invitationRequest, (err)=>
                  return kallback err if err
                  @emit 'NewInvitationRequest'
                  unless @slug is 'koding' # comment out to test with koding group
                    invitationRequest.sendRequestNotification(
                      account, email, invitationType
                    )
                  kallback null

        unless delegate instanceof JAccount
          return callback new KodingError 'Email address is missing'  unless formData?.email
          cb formData.email, (err)=>
            return callback err  if err
            JInvitation = require '../invitation'
            JInvitation.createViaGroupWithoutNotification account, this, [formData.email], callback
        else
          JUser.one username:delegate.profile.nickname, (err, user)=>
            return callback err if err
            cb user.email, callback

  approveMember:(member, roles, callback)->
    [callback, roles] = [roles, callback]  unless callback
    roles ?= ['member']
    queue = roles.map (role)=>=>
      @addMember member, role, queue.fin.bind queue
    dash queue, =>
      callback()
      @updateCounts()
      @cycleChannel()
      @emit 'MemberAdded', member

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
    Relationship.count
      as         : 'member'
      targetName : 'JAccount'
      sourceId   : @getId()
      sourceName : 'JGroup'
    , (err, count)=>
      @update ($set: 'counts.members': count), ->

  leave: secure (client, options, callback)->

    [callback, options] = [options, callback] unless callback

    if @slug is 'koding'
      return callback new KodingError 'Leaving Koding group is not supported yet'

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
        Joinable::leave.call @, client, {as:role}, (err)->
          return kallback err if err
          queue.fin()

      dash queue, kallback

  kickMember: permit 'grant permissions',
    success: (client, accountId, callback)->
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

          kallback = (err)=>
            @updateCounts()
            @cycleChannel()
            callback err

          queue = roles.map (role)=>=>
            @removeMember account, role, (err)->
              return kallback err if err
              queue.fin()

          dash queue, kallback

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

        => @fetchReadme (err, readme)->
          removeHelper readme, err, callback, queue

        => @fetchInvitationRequests (err, requests)->
          JInvitationRequest = require '../invitationrequest'
          removeHelperMany JInvitationRequest, requests, err, callback, queue

        => @fetchVocabularies (err, vocabularies)->
          JVocabulary = require '../vocabulary'
          removeHelperMany JVocabulary, vocabularies, err, callback, queue

        => @fetchTags (err, tags)->
          JTag = require '../tag'
          removeHelperMany JTag, tags, err, callback, queue

        => @fetchApplications (err, apps)->
          JApp = require '../app'
          removeHelperMany JApp, apps, err, callback, queue

        # needs to be tested once subgroups are supported
        # => @fetchSubgroups (err, groups)=>
        #   return callback err if err
        #   return queue.next() unless groups
        #   ids = (model._id for model in groups)
        #   JGroup.remove client, (_id: $in: ids), (err)->
        #     return callback err if err
        #     queue.next()

        => remove_.call this, (err)->
          return callback err if err
          queue.next()

        => @constructor.emit 'GroupDestroyed', this, ->
          queue.next()

        -> callback null
      ]

  sendNotificationToAdmins: (event, contents)->
    @fetchAdmins (err, admins)=>
      unless err
        for admin in admins
          admin.sendNotification event, contents
 
  updateBundle: (formData, callback = (->)) ->
    @fetchBundle (err, bundle) =>
      return callback err  if err?
      bundle.update $set: { overagePolicy: formData.overagePolicy,  }, callback
      bundle.fetchLimits (err, limits) ->
        return callback err  if err?
        queue = limits.map (limit) -> ->
          limit.update { $set: quota: formData.quotas[limit.title] }, fin
        dash queue, callback
        fin = queue.fin.bind queue
 
  updateBundle$: permit 'change bundle',
    success: (client, formData, callback)->
      @updateBundle formData, callback
 
  destroyBundle: (callback) ->
    @fetchBundle (err, bundle) =>
      return callback err  if err?
      return callback new KodingError 'Bundle not found!'  unless bundle?
 
      bundle.remove callback
 
  destroyBundle$: permit 'change bundle',
    success: (client, callback) -> @destroyBundle callback
 
  createBundle: (limits, callback) ->
    @fetchBundle (err, bundle) =>
      return callback err  if err?
      return callback new KodingError 'Bundle exists!'  if bundle?
 
      JGroupBundle = require '../bundle/groupbundle'
 
      bundle = new JGroupBundle {}, limits
      bundle.save (err) =>
        return callback err  if err?
 
        @addBundle bundle, callback
 
  createBundle$: permit 'change bundle',
    success: (client, limits, callback) -> @createBundle limits, callback
 
  fetchBundle$: permit 'commission resources',
    success: (client, rest...) -> @fetchBundle rest...
 
  getDefaultLimits:->
    {
      cpu             : { quota: 1 }
      ram             : { quota: 64 }
      disk            : { quota: 500 }
      users           : { quota: 20 }
    }