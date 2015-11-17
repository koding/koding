SidebarMachineList = require './sidebarmachinelist'
kd = require 'kd'


module.exports = class SidebarSharedMachinesList extends SidebarMachineList

  constructor: (options = {}, data) ->

    options.title       = 'Shared VMs'
    options.hasPlusIcon = no
    options.cssClass    = 'shared-machines'

    super options, data

    @hide()  if data.length is 0

    @on 'MachineBoxDestroyed', =>
      @hide()  if @machineBoxes.length is 0


  # Don't anything when sidebar title is clicked.
  headerClickHandler: ->
