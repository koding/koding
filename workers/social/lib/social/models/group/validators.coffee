{Relationship} = require 'jraphical'

fetchGroup =(model, callback)->
  JGroup = require '../group'
  if model instanceof JGroup
    callback null, model, model.slug
  else
    groupName = @group
    JGroup.one {slug:groupName}, (err, group)->
      callback err, group, groupName

getRoles =(permission, permissionSet)->
  break   for perm in permissionSet.permissions\
          when perm.title in permission
  roles = (perm?.roles or []).concat 'admin' # admin can do anything!

module.exports =

  own:(client, permission, permissionSet, callback)->
    console.warn 'Validators#own is not yet implemented.'
    # {delegate} = client.connection
    # delegateId = delegate.getId()
    # fetchGroup this, (err, group)=>
    #   if err then callback err
    #   else unless group then callback null, no
    #   else
    #     if delegateId.equals @originId
    #       callback null, yes
    #     else
    #       Relationship.count {
    #         sourceId  : delegateId
    #         targetId  : @_id
    #         as        : 'owner'
    #       }, (err, count)->
    #         if err then callback err
    #         else unless count then callback null, no
    #         else

    #           callback null, count > 0

  any:(client, permission, permissionSet, callback)->
    {delegate} = client.connection
    fetchGroup this, (err, group, groupName)->
      if err then callback err
      else unless group then callback null, no
      else
        roles = getRoles permission, permissionSet
        relationshipSelector =
          targetId  : group.getId()
          sourceId  : client.connection.delegate.getId()
          as        : { $in: roles }
        Relationship.count relationshipSelector, (err, count)->
          if count > 0 then callback null, yes
          else callback null