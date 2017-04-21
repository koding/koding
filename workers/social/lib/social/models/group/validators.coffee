{ Relationship } = require 'jraphical'

getRoles = (permission, permissionSet) ->
  return []  unless permissionSet
  roles = ( perm.role for perm in permissionSet.permissions \
                      when permission in perm.permissions )
  roles.push 'admin' # admin can do anything!
  return roles


getRoleSelector = (delegate, group, permission, permissionSet) ->
  roles       = getRoles permission, permissionSet
  return -1   if 'guest' in roles # everyone is (at least) guest!
  return {
    sourceId  : group.getId()
    targetId  : delegate.getId()
    as        : { $in: roles }
  }


createExistenceCallback = (callback) -> (err, count) ->
  if err then callback err, no
  else if count > 0 then callback null, yes
  else callback null, no


hasDelegate = (delegate, callback) ->

  unless delegate
    console.warn 'Delegate cannot be null for checking permissions, request is denied'
    callback null, no
    return no

  return yes


module.exports = Validators =

  own: (client, group, permission, permissionSet, _, callback) ->

    { delegate } = client.connection

    return  unless hasDelegate delegate, callback
    return callback null, yes  if delegate.equals this

    Validators.any client, group, permission, permissionSet, _, (err, allow) =>

      if err or not allow
        return callback err, no

      delegateId = delegate.getId()

      if @originId? and delegateId.equals @originId
        callback null, yes

      else
        ownerSelector =
          $or : [
            {
              sourceId    : delegateId
              targetId    : @getId()
              as          : 'owner'
            }
            # cc: ~GG
            # there is a misdirected relationship between JGroup and JAccount
            # which prevents previous logic to work for ownership validation
            # this additional query will cover that one for JGroup only
            # this must be removed once relationship is updated ~ Hakan
            {
              sourceName  : 'JGroup'
              sourceId    : @getId()
              targetId    : delegateId
              as          : 'owner'
            }
          ]

        Relationship.count ownerSelector, createExistenceCallback callback


  any: (client, group, permission, permissionSet, _, callback) ->

    { delegate } = client.connection
    return  unless hasDelegate delegate, callback

    roleSelector = getRoleSelector delegate, group, permission, permissionSet
    # if we get -1 as the role selector, it means guest (i.e. anyone) is allowed
    return callback null, yes  if roleSelector is -1

    Relationship.count roleSelector, createExistenceCallback callback


  group:

    admin: (client, group, permission, permissionSet, _, callback) ->

      { delegate } = client.connection

      return  unless hasDelegate delegate, callback

      relSelector  =
        targetId   : delegate.getId()
        sourceId   : group.getId()
        as         : { $in: [ 'owner', 'admin' ] }

      Relationship.count relSelector, createExistenceCallback callback

    custom: (customPermission) ->

      (client, group, rest..., callback) ->

        Validators.any client, group, rest..., (err, allow) ->
          if err or not allow
            return callback err, no

          Validators.group.admin client, group, rest..., (err, isAdmin) ->
            callback null, if isAdmin
            then yes
            else !!group.getAt "customize.#{customPermission}"
