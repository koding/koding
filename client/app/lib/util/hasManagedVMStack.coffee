kd = require 'kd'

isManagedVMStack = require './isManagedVMStack'

module.exports = ->

  { stacks } = kd.singletons.computeController

  count = stacks.filter(isManagedVMStack).length

  return count > 0
