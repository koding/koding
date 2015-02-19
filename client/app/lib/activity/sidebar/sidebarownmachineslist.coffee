SidebarMachineList = require './sidebarmachinelist'
MoreVMsModal = require 'app/activity/sidebar/morevmsmodal'
ComputeHelpers = require '../../providers/computehelpers'
Machine = require 'app/providers/machine'


module.exports = class SidebarOwnMachinesList extends SidebarMachineList

  constructor: (options = {}, data) ->

    options.title       = 'Your VMs'
    options.hasPlusIcon = yes
    options.cssClass    = 'my-machines'

    super options, data

    @on 'ListHeaderPlusIconClicked', -> ComputeHelpers.handleNewMachineRequest()

    @on 'ListHeaderClicked', =>

      machines = []

      machines.push new Machine machine: obj.machine  for obj in data

      new MoreVMsModal {}, machines
