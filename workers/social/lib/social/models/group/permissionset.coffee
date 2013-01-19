{Model, secure, dash} = require 'bongo'
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
    index                   :
      'permissions.module'  : 'sparse'
      'permissions.roles'   : 'sparse'
      'permissions.title'   : 'sparse'
    schema                  :
      permissions           :
        type                : Array
        default             : []

  {intersection} = require 'underscore'

  KodingError = require '../../error'

  @checkPermission =(client, permission, target, callback)->
    JGroup = require '../group'
    permission = [permission]  unless Array.isArray permission
    groupName =\
      if 'function' is typeof target
        module = target.name
        client.context.group ? 'koding'
      else if target instanceof JGroup
        module = 'JGroup'
        target.slug
      else
        module = target.constructor.name
        target.group
    JGroup.one {slug: groupName}, (err, group)->
      return callback null  if err
      # permissionSelector = 'permissions.title':
      #   if permission.length is 1 then permission[0]
      #   else $in: permission
      # options = targetOptions: selector: permissionSelector
      # group.fetchPermissionSet {}, options, (err, permissionSet)->
      group.fetchPermissionSet (err, permissionSet)->
        return callback null  if err or not permissionSet
        break   for perm in permissionSet.permissions\
                when perm.title in permission
        roles = (perm?.roles or []).concat 'admin' # admin can do anything!
        relationshipSelector =
          targetId: group.getId()
          sourceId: client.connection.delegate.getId()
          as: { $in: roles }
        console.log {relationshipSelector}
        Relationship.one relationshipSelector, (err, rel)->
          return callback null, yes  if rel
          callback null

  @permit =(permission, promise)->
    [promise, permission] = [permission, promise]  unless promise
    if promise.advanced
      return console.warn "PermissionSet#permit(promise.advanced) is not yet implemented!"
    secure (client, rest...)->
      if 'function' is typeof rest[rest.length-1]
        [rest..., callback] = rest
      else
        callback =->
      success =
        if 'function' is typeof promise then promise.bind this
        else promise.success.bind this
      failure = (promise.failure?.bind this) ? (args...)-> callback args...
      {delegate} = client.connection
      JPermissionSet.checkPermission(client, permission, this,
        (err, hasPermission)->
          if err
            failure err
          else if hasPermission
            success.apply this, [client, rest..., callback]
          else
            failure new KodingError 'Access denied!'
      )
