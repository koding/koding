remote = require('../remote').getInstance()
whoami = require './whoami'
notify_ = require './notify_'

module.exports = (groupName, callback) ->
  return callback null unless groupName
  user = whoami()

  user.checkGroupMembership groupName, (err, isMember) ->
    return callback err  if err
    return callback null if isMember

    #join to group
    remote.api.JGroup.one { slug: groupName }, (err, currentGroup) ->
      return callback err if err
      return callback null unless currentGroup
      currentGroup.join (err) ->
        return callback err if err
        notify_ "You have joined to #{groupName} group!", 'success'
        return callback null
