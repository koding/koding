MANAGED_VMS = 'Managed VMs'

module.exports = (stacks = []) ->

  stacks.sort (a, b) ->

    return  1  if a.title is MANAGED_VMS
    return -1  if b.title is MANAGED_VMS

    return new Date(a.meta.createdAt) - new Date(b.meta.createdAt)
