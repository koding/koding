{Model, secure, dash, daisy} = require 'bongo'
{Module, Relationship} = require 'jraphical'

# class JPermission extends Model
#   @set
#     indexes   :
#       module  : 'sparse'
#       title   : 'sparse'
#       roles   : 'sparse'
#     schema    :
#       module  : String
#       title   : String
#       body    : String
#       roles   : [String]

module.exports = class JPermissionSet extends Module

  @share()

  @set
    softDelete              : yes
    indexes                 :
      'permissions.module'  : 'sparse'
      'permissions.roles'   : 'sparse'
      'permissions.title'   : 'sparse'
    sharedEvents            :
      static                : []
      instance              : [
        'updateInstance'
      ]
    schema                  :
      isCustom              :
        type                : Boolean
        default             : yes
      permissions           :
        type                : Array
        default             : -> []

  {intersection} = require 'underscore'

  KodingError = require '../../error'

  constructor:(data={}, options={})->
    super data
    unless @isCustom
      # initialize the permission set with some sane defaults:
      {permissionDefaultsByModule} = require '../../traits/protected'
      permissionsByRole = {}

      options.privacy ?= 'public'
      for own module, modulePerms of permissionDefaultsByModule
        for own perm, roles of modulePerms
          if roles.public? or roles.private?
            roles = roles[options.privacy] ?= []
          for role in roles
            permissionsByRole[module]       ?= {}
            permissionsByRole[module][role] ?= []
            permissionsByRole[module][role].push perm

      @permissions = []
      for own module, moduleRoles of permissionsByRole
        for own role, modulePerms of moduleRoles
          @permissions.push {module, role, permissions: modulePerms}

  @wrapPermission = wrapPermission =(permission)->
    [{permission, validateWith: require('./validators').any}]

  @checkPermission =(client, advanced, target, callback)->
    JGroup = require '../group'
    advanced = wrapPermission advanced  if 'string' is typeof advanced
    kallback = (group, permissionSet)->
      queue = advanced.map ({permission, validateWith})->->
        validateWith ?= (require './validators').any
        validateWith.call target, client, group, permission, permissionSet,
          (err, hasPermission)->
            if err then queue.next err
            else if hasPermission
              callback null, yes  # we can stop here.  One permission is enough.
            else queue.next()
      queue.push ->
        # if we ever get this far, it means the user doesn't have permission.
        callback null, no
      daisy queue
    # permission = [permission]  unless Array.isArray permission
    groupName =\
      if 'function' is typeof target
        module = target.name
        client.context.group ? 'koding'
      else if target instanceof JGroup
        module = 'JGroup'
        target.slug
      else
        module = target.constructor.name
        target.group ? client.context.group ? 'koding'

    client.groupName = groupName
    JGroup.one {slug: groupName}, (err, group)->
      if err then callback err, no
      else unless group?
        callback new KodingError "Unknown group! #{groupName}"
      else
        group.fetchPermissionSet (err, permissionSet)->
          if err then callback err, no
          else unless permissionSet 
            group.fetchDefaultPermissionSet (err, permissionSet) ->
              return callback err if err
              kallback group, permissionSet
          else
            kallback group, permissionSet

  @permit =(permission, promise)->
    # parameter hockey to allow either parameter to be optional
    if arguments.length is 1 and 'string' isnt typeof permission
      [promise, permission] = [permission, promise]
    promise ?= {}
    # convert simple rules to complex rules:
    advanced =
      if promise.advanced then promise.advanced
      else wrapPermission permission
    # Support a "stub" form of permit that simply calls back with yes if the
    # permission is supported:
    promise.success ?= (client, callback)-> callback null, yes
    # return the validator:
    permit = secure (client, rest...)->
      if 'function' is typeof rest[rest.length-1]
        [rest..., callback] = rest
      else
        callback =->
      success =
        if 'function' is typeof promise then promise.bind this
        else promise.success.bind this
      failure = promise.failure?.bind this
      {delegate} = client.connection
      JPermissionSet.checkPermission client, advanced, this,
        (err, hasPermission, roles)->
          client.roles = roles
          args = [client, rest..., callback]
          if err then callback err
          else if hasPermission
            success.apply null, args
          else if failure?
            failure.apply null, args
          else
            callback new KodingError 'Access denied'
