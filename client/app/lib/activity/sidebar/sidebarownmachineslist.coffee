SidebarMachineList = require './sidebarmachinelist'

module.exports = class SidebarOwnMachinesList extends SidebarMachineList

  constructor: (options = {}, data) ->

    options.title       = 'Your VMs'
    options.hasPlusIcon = yes
    options.cssClass    = 'my-machines'

    super options, data
