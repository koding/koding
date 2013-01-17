{Model, secure, dash} = require 'bongo'
{Module} = require 'jraphical'

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

  @checkPermission =(delegate, permission, target, callback)->
    permission = [permission] unless Array.isArray permission
    target.fetchAuthorityChain (err, chain)->
      if err
        callback err
      else
        console.log {chain}
        permissions = []
        queue = chain.map (group)->->
          delegate.fetchRoles group, (err, roles)->
            console.log roles
            if err then queue.fin(err)
            else if roles.length
              if 'admin' in roles
                permissions.push yes
                queue.fin()
              else if ('moderator' in roles or 'member' in roles) or \
                      group.privacy is 'public' and 'guest' in roles
                group.fetchPermissionSet (err, permissionSet)->
                  if err then queue.fin(err)
                  else if permissionSet?
                    matchingPermissions = [].filter.call(
                      permissionSet.permissions
                      (savedPermission)->
                        savedPermission.module is target.constructor.name and\
                        savedPermission.role in roles and\
                        !!intersection permission, savedPermission.permissions
                    )
                    permissions.push !!matchingPermissions.length
                    queue.fin()
                  else
                    console.log 'there was no permission set found!'
              else
                permissions.push no
                queue.fin()
            else permissions.push no
        dash queue, ->
          hasPermission = yes in permissions
          callback null, hasPermission

  @permit =(permission, promise)->
    secure (client, rest...)->
      if 'function' is typeof rest[rest.length-1]
        [rest..., callback] = rest
      else
        callback =->
      success =
        if 'function' is typeof promise then promise.bind(@)
        else promise.success.bind(@)
      failure = promise.failure?.bind(@) ? (args...)-> callback args...
      {delegate} = client.connection
      JPermissionSet.checkPermission(
        delegate
        permission
        this
        (err, hasPermission)->
          if err
            failure err
          else if hasPermission
            success.apply this, [client, rest..., callback]
          else
            failure new KodingError 'Access denied!'
      )
