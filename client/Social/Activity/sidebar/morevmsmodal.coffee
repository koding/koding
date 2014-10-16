class MoreVMsModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.title          or= 'VMs'
    options.disableSearch    = yes
    options.itemClass      or= SidebarVMItem

    super options, data

  viewAppended: ->

    super

    @addSubView new KDButtonView
      title    : "Add VMs"
      callback : KD.singletons.computeController
        .bound 'handleNewMachineRequest'



  populate: ->

    machines = @getData()

    @listController.addItem machine.data for machine in machines


