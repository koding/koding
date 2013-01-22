{Relationship} = require 'jraphical'

fetchGroup =(model, failure, success)->
  JGroup = require '../group'
  if model instanceof JGroup
    success model, model.slug
  else
    groupName = @group
    JGroup.one {slug:groupName}, (err, group)->
      if err then failure err
      else unless group then failure null, no
      else success group, groupName

getRoles =(permission, permissionSet)->
  roles = (perm.role for perm in permissionSet.permissions\
          when permission in perm.permissions)
  roles.concat 'admin' # admin can do anything!

module.exports =

  own:(client, permission, permissionSet, callback)->
    {delegate} = client.connection
    fetchGroup this, callback, (group, groupName)=>
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

  any:(client, permission, permissionSet, callback)->
    {delegate} = client.connection
    fetchGroup this, callback, (group, groupName)->
      roles = getRoles permission, permissionSet
      relationshipSelector =
        targetId  : group.getId()
        sourceId  : client.connection.delegate.getId()
        as        : { $in: roles }
      Relationship.count relationshipSelector, (err, count)->
        if err then callback err, no
        else if count > 0 then callback null, yes
        else callback null