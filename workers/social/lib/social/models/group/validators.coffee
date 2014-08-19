{Relationship} = require 'jraphical'

getRoles = (permission, permissionSet)->
  return []  unless permissionSet
  roles = (perm.role for perm in permissionSet.permissions\
          when permission in perm.permissions)
  roles.push 'admin' # admin can do anything!
  return roles

getRoleSelector = (delegate, group, permission, permissionSet)->
  roles       = getRoles permission, permissionSet
  return -1   if 'guest' in roles # everyone is (at least) guest!
  return {
    sourceId  : group.getId()
    targetId  : delegate.getId()
    as        : { $in: roles }
  }

createExistenceCallback = (callback)-> (err, count)->
  if err then callback err, no
  else if count > 0 then callback null, yes
  else callback null, no

module.exports =

  own:(client, group, permission, permissionSet, callback)->
    {delegate} = client.connection

    return callback null, yes  if delegate.equals this

    roleSelector = getRoleSelector delegate, group, permission, permissionSet
    # if we get -1 as the role selector, it means guest (i.e. anyone) is allowed
    return callback null, yes  if roleSelector is -1
    Relationship.count roleSelector, (err, count)=>
      if err then callback err, no
      else if count is 0 then callback null, no
      else
        delegateId = delegate.getId()
        if @originId? and delegateId.equals @originId
          callback null, yes
        else
          ownerSelector = {
            sourceId  : delegateId
            targetId  : @getId()
            as        : 'owner'
          }
          Relationship.count ownerSelector, createExistenceCallback callback

  any:(client, group, permission, permissionSet, callback)->
    {delegate} = client.connection
    unless delegate
      console.warn "Delegate cannot be null for checking permissions, request is denied"
      return callback null, no
    roleSelector = getRoleSelector delegate, group, permission, permissionSet
    return callback null, yes  if roleSelector is -1
    Relationship.count roleSelector, createExistenceCallback callback
