class MoreVMsModal extends SidebarSearchModal

  constructor: (options = {}, data) ->

    options.cssClass         = KD.utils.curry 'more-modal more-vms', options.cssClass
    options.width            = 462
    options.title          or= 'VMs'
    options.disableSearch    = yes
    options.itemClass      or= SidebarVMItem
    options.bindModalDestroy = no

    super options, data

  viewAppended: ->

    @addButton = new KDButtonView
      title    : "Add VMs"
      style    : 'add-big-btn'
      icon     : yes
      loader   : yes
      callback : =>
        @addButton.showLoader()
        ComputeHelpers.handleNewMachineRequest @bound 'destroy'

    @addSubView @addButton, '.kdmodal-content'

    super


  populate: ->

    machines = @getData()

    @listController.addItem machine.data for machine in machines


