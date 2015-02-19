SidebarMachineList = require './sidebarmachinelist'
MoreVMsModal = require 'app/activity/sidebar/morevmsmodal'
globals = require 'globals'
ComputeHelpers = require '../../providers/computehelpers'


module.exports = class SidebarOwnMachinesList extends SidebarMachineList

  constructor: (options = {}, data) ->

    options.title       = 'Your VMs'
    options.hasPlusIcon = yes
    options.cssClass    = 'my-machines'

    super options, data

    @on 'ListHeaderClicked', ->
      new MoreVMsModal {}, globals.userMachines

    @on 'ListHeaderPlusIconClicked', ->
      ComputeHelpers.handleNewMachineRequest()
