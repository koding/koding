{Model, secure, dash} = require 'bongo'
{Module, Relationship} = require 'jraphical'

class JPermission extends Model
  @set
    indexes   :
      module  : 'sparse'
      title   : 'sparse'
      roles   : 'sparse'
    schema    :
      module  : String
      title   : String
      body    : String
      roles   : [String]

module.exports = class JPermissionSet extends Module

  @share()

  @set
    schema        :
      permissions : [JPermission]

  {intersection} = require 'underscore'

  KodingError = require '../../error'

  @checkPermission =(client, permission, target, callback)->
    JGroup = require '../group'
    permission = [permission]  unless Array.isArray permission
    if 'function' is typeof target
      groupName = client.context.group ? 'koding'
      module    = target.name
    else
      target.group
    JGroup.one {slug: groupName}, (err, group)->
      return callback null  if err
      permissionSelector = 'permissions.title':
        if permission.length is 1 then permission[0]
        else $in: permission
      options = targetOptions: selector: permissionSelector
      group.fetchPermissionSet {}, options, (err, permissionSet)->
        return callback null  if err or not permissionSet
        break   for perm in permissionSet.permissions\
                when perm.title in permission
        Relationship.one {
          targetId: group.getId()
          sourceId: client.connection.delegate.getId()
          as: { $in: perm.roles }
        }, (err, rel)->
          return callback null, yes  if rel
          callback null

  @permit =(permission, promise)->
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
