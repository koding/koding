kd = require 'kd'


module.exports = (callback) ->

  { groupsController } = kd.singletons

  groupsController.ready =>
    currentGroup = groupsController.getCurrentGroup()
    currentGroup.fetchMyRoles (err, roles) =>

      return callback err  if err

      isAdmin = no

      if 'admin' in (roles ? [])
        isAdmin = yes

      return callback null, isAdmin

