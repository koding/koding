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

    @forwardEvent @machineListView, 'MachineSelected'

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
      title    : "Machine List"
      cssClass : "machines-modal"
      width    : 540
      overlay  : yes
    , options

    super options, data

    @once 'viewAppended', =>
      @addSubView new MachineList @getOption 'listOptions'
