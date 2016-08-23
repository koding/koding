kd = require 'kd'

module.exports = isAdmin = -> kd.singletons.groupsController.canEditGroup()
