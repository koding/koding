{Relationship} = require 'jraphical'

getRoles = (permission, permissionSet)->
  roles = (perm.role for perm in permissionSet.permissions\
          when permission in perm.permissions)
  roles.push 'admin' # admin can do anything!
  return roles

getRoleSelector = (delegate, group, permission, permissionSet)->
  roles       = getRoles permission, permissionSet
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
    roleSelector = getRoleSelector delegate, group, permission, permissionSet
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
    roleSelector = getRoleSelector delegate, group, permission, permissionSet
    Relationship.count roleSelector, createExistenceCallback callback