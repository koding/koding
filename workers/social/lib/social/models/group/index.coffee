{Module} = require 'jraphical'

module.exports = class JGroup extends Module

  {Relationship} = require 'jraphical'

  {Inflector, ObjectRef, secure, daisy, dash} = require 'bongo'

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
      instance      : ['join','leave','modify','fetchPermissions', 'createRole'
                       'updatePermissions', 'fetchMembers', 'fetchRoles', 'fetchMyRoles']
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
        as          : 'group'
      admin         :
        targetType  : 'JAccount'
        as          : 'group'
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
    JName = require '../name'
    {delegate} = client.connection
    JName.claim formData.slug, 'JGroup', 'slug', (err)=>
      if err then callback err
      else
        group         = new @ formData
        permissionSet = null

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
                permissionSet = new JPermissionSet
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
          -> callback null, group
        ]

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

  addDefaultRoles:(callback)->

    group = @
    JGroupRole = require './role'

    JGroupRole.all {isDefault: yes}, (err, roles)->
      if err then callback err
      else
        queue = roles.map (role)->
          ->
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
    console.log 'do we get here?'
    {delegate} = client.connection
    Relationship.someData {
      sourceId: delegate.getId()
      targetId: @getId()
    }, {as:1}, (err, cursor)->
      console.log arguments
      if err then callback err
      else
        cursor.toArray (err, arr)->
          if err then callback err
          else callback null, (doc.as for doc in arr)

  createRole: permit 'grant permissions'
    success:(client, formData, callback)->
      JGroupRole = require './role'
      JGroupRole.create {title : formData.title}, callback

  modify: permit
    advanced : [
      { permission: 'edit own groups', validateWith: Validators.own }
      { permission: 'edit groups' }
    ]
    success : (client, formData, callback)->
      @update {$set:formData}, callback

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