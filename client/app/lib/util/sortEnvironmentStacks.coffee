isManagedVMStack = require './isManagedVMStack'

module.exports = (stacks = []) ->


  stacks.sort (a, b) ->

    return  1  if isManagedVMStack b
    return -1


  stacks.sort (a, b) ->

    return  1  if a.config?.oldOwner
    return -1


  stacks.sort (a, b) ->

    return -1  if a.config?.groupStack
    return  1


  stacks.sort (a, b) ->

    return -1  if new Date(a.meta.modifiedAt) > new Date(b.meta.modifiedAt)
    return  0
