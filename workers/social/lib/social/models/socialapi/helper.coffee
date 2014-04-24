fetchGroup = (client, callback)->
  groupName = client.context.group or "koding"
  JGroup = require '../group'
  JGroup.one slug : groupName, (err, group)=>
    return callback err  if err
    return callback {error: "Group not found"}  unless group

    {delegate} = client.connection
    return callback {error: "Request not valid"} unless delegate
    group.canReadGroupActivity client, (err, res)->
      if err then return callback {error: "Not allowed to open this group"}
      else callback null, group

module.exports = {
  fetchGroup
}
