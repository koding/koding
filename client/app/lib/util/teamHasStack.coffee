kd = require 'kd'

module.exports = teamHasStack = -> !!kd.singletons.groupsController.getCurrentGroup().stackTemplates?.length
