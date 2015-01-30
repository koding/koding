class SidebarOwnMachinesList extends SidebarMachineList

  constructor: (options = {}, data) ->

    options.title       = 'VMs'
    options.hasPlusIcon = yes

    super options, data

    @on 'ListHeaderClicked', ->
      new MoreVMsModal {}, KD.userMachines

    @on 'ListHeaderPlusIconClicked', ->
      ComputeHelpers.handleNewMachineRequest()
