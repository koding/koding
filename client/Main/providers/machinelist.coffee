class MachineList extends KDView

  viewAppended: ->

    @addSubView @loader = new KDLoaderView
      cssClass    : "loader"
      showLoader  : yes
      size        :
        width     : 16

    @addSubView @container = new KDView
    @machineListController = new KDListViewController
      selection            : yes
      viewOptions          :
        wrapper            : yes
        itemClass          : MachineItemListView
        itemOptions        : @getOption 'itemOptions'
      noItemFoundWidget    : new KDView
        cssClass           : 'noitem-warning'
        partial            : "There is no machine to show for now."

    @container.addSubView \
      @machineListView = @machineListController.getView()

    @forwardEvent @machineListController, 'ItemSelectionPerformed'

    @fetchMachines()


  fetchMachines: ->

    { query } = @getOptions()
    query    ?= {}

    @loader.show()

    {computeController} = KD.singletons
    computeController.queryMachines query, (err, machines)=>

      # TODO handle errors correctly
      return if KD.showError err

      @loader.hide()
      @machineListController.replaceAllItems machines


class MachineListModal extends KDModalView

  constructor: (options = {}, data)->

    options = $.extend
      title        : "Machine List"
      subtitle     : "Select a running machine below to perform this action."
      cssClass     : "machines-modal"
      width        : 540
      overlay      : yes
      buttons      :
        "Continue" :
          disabled : yes
          callback : => @continueAction()
    , options

    super options, data

  viewAppended:->

    @addSubView machineList = new MachineList @getOption 'listOptions'

    machineList.on "ItemSelectionPerformed", (list, {items})=>

      @machine = items.first.getData()
      @buttons["Continue"][ \
        if @checkMachineState() then 'enable' else 'disable'
      ]()


  checkMachineState: ->

    # FIXME Make this check extendable
    @machine?.status.state is Machine.State.Running


  continueAction:->

    if @checkMachineState()
      @emit "MachineSelected", @machine
      @destroy()
