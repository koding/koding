{Module} = require 'jraphical'

module.exports = class JGroup extends Module

  {Relationship} = require 'jraphical'

  {Inflector, ObjectRef, secure} = require 'bongo'

  JPermissionSet = require './permissionset'
  {permit} = JPermissionSet

  KodingError = require '../../error'

  @trait __dirname, '../../traits/followable'
  @trait __dirname, '../../traits/filterable'
  @trait __dirname, '../../traits/taggable'
  @trait __dirname, '../../traits/protected'

  @share()

  @set
    feedable        : no
    memberRoles     : ['admin','moderator','member','guest']
    permissions     : [
      'grant permissions'
      'create groups'
      'edit groups'
      'edit own groups'
    ]
    indexes         :
      slug          : 'unique'
    sharedMethods   :
      static        : ['one','create','byRelevance','someWithRelationship','__resetAllGroups']
      instance      : ['join','leave','fetchPermissions','updatePermissions','modify']
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
        as          : 'group'
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

  @__resetAllGroups = secure (client, callback)->
    {delegate} = client.connection
    @drop callback if delegate.can 'reset groups'

  @fetchParentGroup =(source, callback)->
    Relationship.someData {
      targetName  : @name
      sourceId    : source.getId()
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
        group = new @ formData
        group.save (err)->
          if err
            callback err
          else
            console.log 'group is saved'
            group.addMember delegate, (err)->
              if err
                callback err
              else
                console.log 'member is added'
                group.addAdmin delegate, (err)->
                  if err
                    callback err
                  else
                    console.log 'admin is added'
                    permissionSet = new JPermissionSet
                    permissionSet.save (err)->
                      if err
                        callback err
                      else
                        console.log 'permissionSet is saved'
                        group.addPermissionSet permissionSet, (err)->
                          if err
                            callback err
                          else
                            console.log 'permissionSet is added'
                            delegate.addGroup group, 'admin', (err)->
                              if err
                                callback err
                              else
                                console.log 'group is added'
                                callback null, group

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

  updatePermissions: permit 'grant permissions'
    success:(client, permissions, callback=->)->
      @fetchPermissions client, (err, permissionSet)=>
        if err
          callback err
        else if permissionSet?
          # TODO: permissionSet.permissionSet is botched.
          console.log 'there is a permission set', permissionSet, permissionSet.constructor
          permissionSet.permissionSet.update $set:{permissions}, callback
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
            permissionSet: permissionSet
          }

  modify: permit(['edit groups','edit own groups'],
    success:(client, formData, callback)->
      @update {$set:formData}, callback
  )

  join: secure (client, callback)->
    callback new KodingError 'JGroup#join is unimplemented'

  leave: secure (client, callback)->
    callback new KodingError 'JGroup#leave is unimplemented'
