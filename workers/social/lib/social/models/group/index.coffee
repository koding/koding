{Module} = require 'jraphical'

module.exports = class JGroup extends Module

  [ERROR_UNKNOWN, ERROR_NO_POLICY, ERROR_POLICY] = [403010, 403001, 403009]

  {Relationship} = require 'jraphical'

  {Inflector, ObjectId, ObjectRef, secure, daisy, dash} = require 'bongo'

  JPermissionSet = require './permissionset'
  {permit} = JPermissionSet

  KodingError = require '../../error'

  Validators = require './validators'

  @trait __dirname, '../../traits/followable'
  @trait __dirname, '../../traits/filterable'
  @trait __dirname, '../../traits/taggable'
  @trait __dirname, '../../traits/protected'
  @trait __dirname, '../../traits/joinable'

  @share()

  @set
    feedable        : no
    memberRoles     : ['admin','moderator','member','guest']
    permissions     :
      'grant permissions'                 : []
      'open group'                        : ['member', 'moderator']
      'list members'                      : ['member', 'moderator']
      'create groups'                     : ['moderator']
      'edit groups'                       : ['moderator']
      'edit own groups'                   : ['member', 'moderator']
      'query collection'                  : ['member', 'moderator']
      'update collection'                 : ['moderator']
      'assure collection'                 : ['moderator']
      'remove documents from collection'  : ['moderator']
    indexes         :
      slug          : 'unique'
    sharedMethods   :
      static        : [
        'one','create','each','byRelevance','someWithRelationship'
        '__resetAllGroups', 'fetchMyMemberships'
      ]
      instance      : [
        'join','leave','modify','fetchPermissions', 'createRole'
        'updatePermissions', 'fetchMembers', 'fetchRoles', 'fetchMyRoles'
        'fetchUserRoles','changeMemberRoles','canOpenGroup', 'canEditGroup'
        'fetchMembershipPolicy','modifyMembershipPolicy','requestInvitation'
        'fetchReadme', 'setReadme', 'addCustomRole'
      ]
    schema          :
      title         :
        type        : String
        required    : yes
      body          : String
      avatar        : String
      slug          :
        type        : String
        default     : -> Inflector.dasherize @title.toLowerCase()
      privacy       :
        type        : String
        enum        : ['invalid privacy type', ['public', 'private']]
      visibility    :
        type        : String
        enum        : ['invalid visibility type', ['visible', 'hidden']]
      parent        : ObjectRef
    relationships   :
      permissionSet :
        targetType  : JPermissionSet
        as          : 'owner'
      member        :
        targetType  : 'JAccount'
        as          : 'member'
      moderator     :
        targetType  : 'JAccount'
        as          : 'moderator'
      admin         :
        targetType  : 'JAccount'
        as          : 'admin'
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
      readme        :
        targetType  : 'JReadme'
        as          : 'owner'

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

  @create = secure (client, formData, callback)->
    JPermissionSet = require './permissionset'
    JMembershipPolicy = require './membershippolicy'
    JName = require '../name'
    {delegate} = client.connection
    JName.claim formData.slug, 'JGroup', 'slug', (err)=>
      if err then callback err
      else
        group             = new @ formData
        permissionSet     = new JPermissionSet
        queue = [
          -> group.save (err)->
              if err then callback err
              else
                console.log 'group is saved'
                queue.next()
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
          -> permissionSet.save (err)->
              if err then callback err
              else
                console.log 'permissionSet is saved'
                queue.next()
          -> group.addPermissionSet permissionSet, (err)->
              if err then callback err
              else
                console.log 'permissionSet is added'
                queue.next()
          -> group.addDefaultRoles (err)->
              if err then callback err
              else
                console.log 'roles are added'
                queue.next()
          -> delegate.addGroup group, 'admin', (err)->
              if err then callback err
              else
                console.log 'group is added'
                queue.next()
        ]
        if 'private' is group.privacy
          membershipPolicy  = new JMembershipPolicy
          queue.push(
            -> membershipPolicy.save (err)->
              if err then callback err
              else queue.next()
            -> group.addMembershipPolicy membershipPolicy, (err)->
              if err then callback err
              else queue.next()
          )
        queue.push -> callback null, group

        daisy queue

  @findSuggestions = (seed, options, callback)->
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

  changeMemberRoles: permit 'grant permissions'
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

  updatePermissions: permit 'grant permissions'
    success:(client, permissions, callback=->)->
      @fetchPermissionSet (err, permissionSet)=>
        if err
          callback err
        else if permissionSet?
          permissionSet.update $set:{permissions}, callback
        else
          permissionSet = new JPermissionSet {permissions}
          permissionSet.save callback

  fetchPermissions: permit 'grant permissions'
    success:(client, callback)->
      {permissionsByModule} = require '../../traits/protected'
      {delegate} = client.connection
      @fetchPermissionSet (err, permissionSet)->
        if err
          callback err
        else
          callback null, {
            permissionsByModule
            permissions: permissionSet.permissions
          }

  fetchMyRoles: secure (client, callback)->
    {delegate} = client.connection
    Relationship.someData {
      sourceId: delegate.getId()
      targetId: @getId()
    }, {as:1}, (err, cursor)->
      if err then callback err
      else
        cursor.toArray (err, arr)->
          if err then callback err
          else callback null, (doc.as for doc in arr)

  fetchUserRoles: permit 'grant permissions'
    success:(client, callback)->
      @fetchRoles (err, roles)=>
        roleTitles = (role.title for role in roles)
        Relationship.someData {
          sourceName  : 'JAccount'
          targetId    : @getId()
          as          : { $in: roleTitles }
        }, {as:1, sourceId:1}, (err, cursor)->
          if err then callback err
          else
            cursor.toArray (err, arr)->
              if err then callback err
              else callback null, arr

  fetchMembers$: permit 'list members'
    success:(client, rest...)->
      @fetchMembers rest...

  fetchReadme$: permit 'open group'
    success:(client, rest...)->
      @fetchReadme rest...

  setReadme$: permit 'edit groups'
    success:(client, text, callback)->
      @fetchReadme (err, readme)=>
        unless readme
          JReadme = require '../readme'
          readme = new JReadme
            content : text
          
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
              callback readme
          ]

        else 
          readme.update 
            $set : 
              content : text
          , (err)=>
            if err then callback err
            else callback readme

  createRole: permit 'grant permissions'
    success:(client, formData, callback)->
      JGroupRole = require './role'
      JGroupRole.create 
        title           : formData.title
        isConfigureable : formData.isConfigureable or no
      , callback

  addCustomRole: permit 'grant permissions'
    success:(client,formData,callback)->
      @createRole client,formData, (err,role)=>
        console.log err,role
        unless err
          @addRole role, callback
        else 
          callback err, null

  modify: permit
    advanced : [
      { permission: 'edit own groups', validateWith: Validators.own }
      { permission: 'edit groups' }
    ]
    success : (client, formData, callback)->
      @update {$set:formData}, callback

  modifyMembershipPolicy: permit
    advanced : [
      { permission: 'edit own groups', validateWith: Validators.own }
      { permission: 'edit groups' }
    ]
    success : (client, formData, callback)->
      @fetchMembershipPolicy (err, policy)->
        if err then callback err
        else policy.update $set: formData, callback

  canEditGroup: permit 'grant permissions'
    success:(client, callback)-> callback null, yes

  canOpenGroup: permit 'open group'
    success:(client, callback)-> callback null, yes

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

  requestInvitation: secure (client, callback)->
    JUser = require '../user'
    JInvitationRequest = require '../invitationrequest'
    {delegate} = client.connection
    (new JInvitationRequest {
      koding: { username: delegate.profile.nickname }
      group: @slug
    }).save (err)->
      if err?.code is 11000
        callback new KodingError """
          You've already requested an invitation to this group.
          """

  # attachEnvironment:(name, callback)->
  #   [callback, name] = [name, callback]  unless callback
  #   name ?= @title
  #   JEnvironment.one {name}, (err, env)->
  #     if err then callback err
  #     else if env?
  #       @addEnvironment
  #       callback null, env
  #     else
  #       env = new JEnvironment {name}
  #       env.save (err)->
  #         if err then callback err
  #         else callback null