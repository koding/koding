{Relationship} = require 'jraphical'

getRoles =(permission, permissionSet)->
  roles = (perm.role for perm in permissionSet.permissions\
          when permission in perm.permissions)
  roles.push 'admin' # admin can do anything!
  return roles

module.exports =

  own:(client, group, permission, permissionSet, callback)->
    {delegate} = client.connection
    roles = getRoles permission, permissionSet
    relationshipSelector =
      targetId  : group.getId()
      sourceId  : client.connection.delegate.getId()
      as        : { $in: roles }
    Relationship.count relationshipSelector, (err, count)=>
      if err then callback err, no
      else if count is 0 then callback null, no
      else
        delegateId = delegate.getId()
        if @originId? and delegateId.equals @originId
          callback null, yes
        else
          Relationship.count {
            sourceId  : delegateId
            targetId  : @getId()
            as        : 'owner'
          }, (err, count)->
            if err then callback err, no
            else if count > 0 then callback null, yes
            else callback null, no

  any:(client, group, permission, permissionSet, callback)->
    {delegate} = client.connection
    roles = getRoles permission, permissionSet
    relationshipSelector =
      targetId  : group.getId()
      sourceId  : client.connection.delegate.getId()
      as        : { $in: roles }
    Relationship.count relationshipSelector, (err, count)->
      if err then callback err, no
      else if count > 0 then callback null, yes
      else callback null