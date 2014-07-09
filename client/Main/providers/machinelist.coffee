class MachineList extends KDModalView


  constructor: (options = {}, data)->

    options = $.extend
      title    : "Machine List"
      cssClass : "github-modal"
      width    : 540
      overlay  : yes
    , options

    super options, data


  viewAppended: ->

    @addSubView @loader = new KDLoaderView
      cssClass    : "loader"
      showLoader  : yes
      size        :
        width     : 16

    @addSubView @container = new KDView
      cssClass : 'hidden'

    @machineListController = new KDListViewController
      selection         : yes
      viewOptions       :
        type            : 'machine'
        wrapper         : yes
        itemClass       : MachineItemListView
        itemOptions     :
          buttonTitle   : 'select'
      noItemFoundWidget : new KDView
        cssClass        : 'noitem-warning'
        partial         : "There is no machine to show for now."

    @container.addSubView \
      @machineListView = @machineListController.getView()

    @forwardEvent @machineListView, 'MachineSelected'

    @fetchMachines()


  fetchMachines: ->

    @loader.show()

    {computeController} = KD.singletons
    computeController.fetchMachines (err, machines)=>

      # TODO handle errors correctly
      return if KD.showError err

      @container.show()
      @loader.hide()

      @machineListController.replaceAllItems machines

