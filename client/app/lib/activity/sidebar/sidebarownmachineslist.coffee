globals            = require 'globals'
SidebarMachineList = require './sidebarmachinelist'

module.exports = class SidebarOwnMachinesList extends SidebarMachineList

  constructor: (options = {}, data) ->

    if globals.currentGroup.slug isnt 'koding'
      title = "#{globals.currentGroup.title} VM Stack"

    options.title       = title ? 'Your VMs'
    options.hasPlusIcon = yes
    options.cssClass    = 'my-machines'

    super options, data
