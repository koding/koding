{Module} = require 'jraphical'

module.exports = class JGroup extends Module

  {Inflector, ObjectRef, secure} = require 'bongo'

  @trait __dirname, '../../traits/followable'
  @trait __dirname, '../../traits/filterable'
  @trait __dirname, '../../traits/taggable'
  @trait __dirname, '../../traits/protected'

  @share()

  @set
    memberRoles     : ['admin','moderator','member','guest']
    permissions     : ['grant permissions']
    indexes         :
      slug          : 'unique'
    sharedMethods   :
      static        : ['create','byRelevance','someWithRelationship','__resetAllGroups']
      instance      : ['join','leave','fetchPermissionSet']
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
      permissions   :
        targetType  : 'JPermissionSet'
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

  @create = secure (client, formData, callback)->
    JPermissionSet = require './permissionset'
    {delegate} = client.connection
    group = new @ formData
    group.save (err)->
      if err
        callback err
      else
        group.addMember delegate, (err)->
          if err
            callback err
          else
            group.addAdmin delegate, (err)->
              if err
                callback err
              else
                permissions = new JPermissionSet
                permissions.save (err)->
                  if err
                    callback err
                  else
                    group.addPermissions permissions, (err)->
                      if err
                        callback err
                      else
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

  fetchPermissionSet: secure (client, callback)->
    {permissionsByModule} = require '../../traits/protected'
    {delegate} = client.connection
    @fetchPermissions (err, permissionSet)->
      if err
        callback err
      else
        callback null, {
          permissionsByModule
          permissions: permissionSet.permissions
        }


  join: secure (client, callback)->
    callback 'JGroup#join is unimplemented'

  leave: secure (client, callback)->
    callback 'JGroup#leave is unimplemented'
