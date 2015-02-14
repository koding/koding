kd = require 'kd'
KDView = kd.View
KDLoaderView = kd.LoaderView
KDListViewController = kd.ListViewController
showError = require 'app/util/showError'

module.exports = class MachineList extends KDView

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

    {computeController} = kd.singletons
    computeController.queryMachines query, (err, machines)=>

      # TODO handle errors correctly
      return if showError err

      @loader.hide()
      @machineListController.replaceAllItems machines
