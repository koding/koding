{Module} = require 'jraphical'
_ = require 'underscore'

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

  @trait __dirname, '../../traits/followable'
  @trait __dirname, '../../traits/filterable'
  @trait __dirname, '../../traits/taggable'
  @trait __dirname, '../../traits/protected'
  @trait __dirname, '../../traits/joinable'
  @trait __dirname, '../../traits/slugifiable'

  @share()

  @set
    slugifyFrom     : 'title'
    slugTemplate    : '#{slug}'
    feedable        : no
    memberRoles     : ['admin','moderator','member','guest']
    permissions     :
      'grant permissions'                 : []
      'open group'                        : ['member','moderator']
      'list members'                      : ['member','moderator']
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
    sharedMethods   :
      static        : [
        'one','create','each','byRelevance','someWithRelationship'
        '__resetAllGroups','fetchMyMemberships','__importKodingMembers','broadcast','cycleChannel'
      ]
      instance      : [
        'join', 'leave', 'modify', 'fetchPermissions', 'createRole'
        'updatePermissions', 'fetchMembers', 'fetchRoles', 'fetchMyRoles'
        'fetchUserRoles','changeMemberRoles','canOpenGroup', 'canEditGroup'
        'fetchMembershipPolicy','modifyMembershipPolicy','requestAccess'
        'fetchReadme', 'setReadme', 'addCustomRole', 'fetchInvitationRequests'
        'countPendingInvitationRequests', 'countInvitationRequests'
        'fetchInvitationRequestCounts', 'resolvePendingRequests','fetchVocabulary'
        'fetchMembershipStatuses', 'setBackgroundImage', 'fetchAdmin', 'inviteMember',
        'removeBackgroundImage', 'kickMember', 'transferOwnership'
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

  @create = do->

    save_ =(label, model, queue, callback)->
      model.save (err)->
        if err then callback err
        else
          console.log "#{label} is saved"
          queue.next()

    create = secure (client, formData, callback)->
      JPermissionSet = require './permissionset'
      JMembershipPolicy = require './membershippolicy'
      JName = require '../name'
      {delegate} = client.connection
      group                 = new this formData
      permissionSet         = new JPermissionSet
      defaultPermissionSet  = new JPermissionSet
      queue = [
        -> group.createSlug (err, slug)->
          if err then callback err
          else unless slug?
            callback new KodingError "Couldn't claim the slug!"
          else
            console.log "created a slug #{slug}"
            group.slug  = slug.slug
            group.slug_ = slug.slug
            queue.next()
        -> save_ 'group', group, queue, callback
        -> group.addMember delegate, (err)->
            if err then callback err
            else
              console.log 'member is added'
              queue.next()
        -> group.addAdmin delegate, (err)->
            if err then callback err
            else
              console.log 'admin is added'
              queue.next()
        -> group.addOwner delegate, (err)->
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
        queue.push -> group.createMembershipPolicy -> queue.next()
      queue.push -> callback null, group

      daisy queue

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
          else callback null, (doc.as for doc in arr)

  fetchMyRoles: secure (client, callback)->
    @fetchRolesByAccount client.connection.delegate, callback

  fetchUserRoles: permit 'grant permissions',
    success:(client, callback)->
      @fetchRoles (err, roles)=>
        roleTitles = (role.title for role in roles)
        selector = {
          targetName  : 'JAccount'
          sourceId    : @getId()
          as          : { $in: roleTitles }
        }
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

  renderHomepageHelper: (roles, callback)->
    [callback, roles] = [roles, callback]  unless callback
    roles or= []

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
            roles
            @customize
          }

  fetchHomepageView:(clientId, callback)->
    [callback, clientId] = [clientId, callback]  unless callback

    unless clientId
      @renderHomepageHelper callback
    else
      JSession = require '../session'
      JSession.one {clientId}, (err, session)=>
        if err
          console.error err
          callback err
        else
          {username} = session.data
          if username
            @fetchMembershipStatusesByUsername username, (err, roles)=>
              if err then callback err
              else @renderHomepageHelper roles, callback
          else
            @renderHomepageHelper callback

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

  createMembershipPolicy:(queue, callback)->
    [callback, queue] = [queue, callback]  unless callback
    queue ?= []
    JMembershipPolicy = require './membershippolicy'
    membershipPolicy  = new JMembershipPolicy
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

  convertPublicToPrivate =(group, callback)->
    group.createMembershipPolicy callback

  convertPrivateToPublic =(group, callback)->
    group.destroyMemebershipPolicy callback

  setPrivacy:(privacy)->
    if @privacy is 'public' and privacy is 'private'
      convertPublicToPrivate this
    else if @privacy is 'private' and privacy is 'public'
      convertPrivateToPublic this
    @privacy = privacy

  getPrivacy:-> @privacy

  modify: permit
    advanced : [
      { permission: 'edit own groups', validateWith: Validators.own }
      { permission: 'edit groups' }
    ]
    success : (client, formData, callback)->
      @setPrivacy formData.privacy
      @update {$set:formData}, callback

  modifyMembershipPolicy: permit
    advanced: PERMISSION_EDIT_GROUPS
    success: (client, formData, callback)->
      @fetchMembershipPolicy (err, policy)->
        if err then callback err
        else policy.update $set: formData, callback

  canEditGroup: permit 'grant permissions'

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

          JInvitationRequest = require '../invitationrequest'

          invitationRequestSelector =
            group             : @slug
            status            : 'pending'
            invitationType    : invitationType

          JInvitationRequest.each invitationRequestSelector, {}, (err, request)->
            if err then callback err
            else if request? then request[method+'Invitation'] client, (err)->
              console.error err  if err
            else callback null

  inviteMember: permit 'send invitations',
    success: (client, email, callback)->
      JInvitationRequest = require '../invitationrequest'

      params =
        email: email,
        group: @slug

      JInvitationRequest.one params, (err, invitationRequest)=>
        if invitationRequest
          callback new KodingError """
            You've already invited #{email} to join this group.
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

  requestInvitation: secure (client, invitationType, callback)->
    {delegate} = client.connection
    JInvitationRequest = require '../invitationrequest'

    invitationRequest = new JInvitationRequest {
      invitationType
      koding  : { username: delegate.profile.nickname }
      group   : @slug,
      status  : 'pending'
    }
    invitationRequest.save (err)=>
      if err?.code is 11000
        callback new KodingError """
          You've already requested an invitation to this group.
          """
      else
        @addInvitationRequest invitationRequest, (err)=>
          if err then callback err
          else
            if invitationType is 'basic approval'
              invitationRequest.sendRequestNotification client, callback
            @emit 'NewInvitationRequest'

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
            request.sendInvitation client, ->
              callback null, """
                An invite was sent to:
                <strong>koding+#{request.koding.username}@koding.com</strong>
                """
              setTimeout queue.next.bind(queue), 50
          queue.push -> callback null, null
          daisy queue

  requestAccess: secure (client, callback)->
    @fetchMembershipPolicy (err, policy)=>
      if err then callback err
      else
        if policy?.invitationsEnabled
          invitationType = 'invitation'
        else
          invitationType = 'basic approval'

        @requestInvitation client, invitationType, callback

  approveMember:(member, roles, callback)->
    [callback, roles] = [roles, callback]  unless callback
    roles ?= ['member']
    queue = roles.map (role)=>=>
      @addMember member, role, queue.fin.bind queue
    dash queue, =>
      callback()
      @updateCounts()
      @cycleChannel()
      @emit 'NewMember'

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

      queue = _.intersection(['member', 'admin'], roles).map (role)=>=>
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

          queue = _.intersection(['member', 'admin'], roles).map (role)=>=>
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

      # double check that client is really the owner
      @fetchMyRoles client, (err, roles)=>
        return callback err if err

        if not 'owner' in roles
          return callback new KodingError 'You must be owner to perform this action!'

        JAccount.one _id:accountId, (err, account)=>
          return callback err if err

          @fetchRolesByAccount account, (err, newOwnersRoles)=>
            return callback err if err

            kallback = (err)=>
              @cycleChannel()
              @updateCounts()
              callback err

            # give rights to new owner
            queue = _.difference(['member', 'admin', 'owner'], newOwnersRoles).map (role)=>=>
              @addMember account, role, (err)->
                return kallback err if err
                queue.fin()

            dash queue, =>
              # remove ownership of previous owner
              @removeOwner delegate, kallback
