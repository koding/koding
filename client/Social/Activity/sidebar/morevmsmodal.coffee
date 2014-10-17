class MoreVMsModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass         = KD.utils.curry 'more-vms', options.cssClass
    options.width            = 462
    options.title          or= 'VMs'
    options.disableSearch    = yes
    options.itemClass      or= SidebarVMItem

    super options, data

  viewAppended: ->

    super

    @addButton = new KDButtonView
      title    : "Add VMs"
      style    : 'solid green small'
      callback : KD.singletons.computeController
        .bound 'handleNewMachineRequest'

    @addSubView @addButton, '.kdmodal-title'



  populate: ->

    machines = @getData()

    @listController.addItem machine.data for machine in machines


