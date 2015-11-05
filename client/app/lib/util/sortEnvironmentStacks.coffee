isManagedVMStack = require './isManagedVMStack'

module.exports = (stacks = []) ->

  stacks.sort (a, b) ->

    return  1  if isManagedVMStack a
    return -1  if isManagedVMStack b

    return new Date(a.meta.createdAt) - new Date(b.meta.createdAt)
