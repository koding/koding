kd                                 = require 'kd'
remote                             = require 'app/remote'
snapshotHelpers                    = require './snapshothelpers'
openIdeByMachine                   = require '../util/openIdeByMachine'
JView                              = require '../jview'
MachineSettingsCommonView          = require './machinesettingscommonview'
MachineSettingsSnapshotsController = require './controllers/machinesettingssnapshotscontroller'

module.exports = class MachineSettingsSnapshotsView extends MachineSettingsCommonView

  constructor: (options = {}, data) ->

    options.cssClass             = kd.utils.curry options.cssClass, 'snapshots'
    options.headerTitle          = 'Snapshots'
    options.addButtonTitle       = 'ADD SNAPSHOT'
    options.headerAddButtonTitle = 'ADD NEW SNAPSHOT'

    super options, data

    @listController.getListView().on 'DeleteSnapshot', =>
      @notificationView.hide()
      @listController.showNoItemWidget()

    @listController.getListView().on 'NewVmFromSnapshot', (snapshot) =>
      machine = @getData()
      snapshotHelpers.newVmFromSnapshot snapshot, machine, =>
        @emit 'ModalDestroyRequested'


  createListView: ->

    itemOptions = @getOptions().listViewItemOptions or {}
    itemOptions.machineId = @machine._id

    options =
      viewOptions   :
        wrapper     : yes
        itemOptions : itemOptions

    @listController = new MachineSettingsSnapshotsController options

    @listView = @listController.getView()

    @addSubView @listView


  ###*
   * Display a simple Notification to the user.
  ###
  @notify: (msg = '') ->

    new kd.NotificationView { content: msg }


  ###*
   * The various snapshot total limits.
  ###
  @snapshotsLimits:
    default      : 5
    free         : 0
    hobbyist     : 1
    developer    : 3
    professional : 5


  ###*
   * Overridden from MachineSettingsCommonView to add the learn-more view
   * at the bottom of the view.
  ###
  createElements: ->

    @createHeader()
    @createAddView()
    @createListView()
    @addSubView new kd.CustomHTMLView
      cssClass : 'learn-more'
      partial  : '''
        <a target="_blank" href="https://koding.com/docs/vm-snapshot">Learn more about
        Snapshots</a>
      '''


  ###*
   * Create the header views. Called via MachineSettingsCommonView
  ###
  createHeader: ->

    { headerTitle, headerAddButtonTitle
      addButtonCssClass, loaderOnHeaderButton } = @getOptions()

    @headerAddNewButton = new kd.ButtonView
      title    : headerAddButtonTitle
      cssClass : "solid green small add-button #{addButtonCssClass}"
      loader   : loaderOnHeaderButton
      callback : @bound 'showAddView'

    @addSubView new JView
      tagName         : 'h4'
      cssClass        : 'kdview kdheaderview'
      pistachioParams : { @headerAddNewButton }
      pistachio       : '''
        <span class="column label">Name</span>
        <span class="column created-at">Created at</span>
        <span class="column size">Size</span>
        {{> headerAddNewButton}}
        '''

    @addSubView @notificationView = new kd.CustomHTMLView
      cssClass : 'notification hidden'


  ###*
   * Create a new snapshot with the given name, from the given machineId
   *
   * @param {String} label - The label (name) of the snapshot
   * @param {Function(err:Error, snapshot:JSnapshot)} callback
  ###
  createSnapshot: (label, callback = kd.noop) ->

    computeController = kd.getSingleton 'computeController'
    machine           = @getData()
    machineId         = machine._id
    eventId           = "createSnapshot-#{machineId}"

    monitorProgress = (event) =>
      { error, percentage } = event
      @emit 'SnapshotProgress', percentage
      return  if percentage < 100
      # Remove the subscriber if the percent is >= 100
      computeController.off eventId, monitorProgress
      return callback error  if error
      # Because kloud.createSnapshot does not return a snapshot object,
      # we need to request the newest snapshot (sorted by creation date)
      snapshotHelpers.fetchNewestSnapshot machineId, callback

    computeController.createSnapshot machine, label
      .catch callback
      .then -> computeController.on eventId, monitorProgress


  ###*
   * Create the add new snapshot buttons. Overloading
   * MachineSettingsCommonView's method to swap the button order.
  ###
  createAddNewViewButtons: ->
    wrapper = new kd.CustomHTMLView { cssClass: 'buttons' }

    wrapper.addSubView new kd.CustomHTMLView
      tagName  : 'span'
      partial  : 'cancel'
      cssClass : 'cancel'
      click    : @bound 'hideAddView'

    wrapper.addSubView @addNewButton = new kd.ButtonView
      cssClass : 'solid green small add'
      loader   : yes
      title    : @getOptions().addButtonTitle
      callback : @bound 'handleAddNew'

    @addViewContainer.addSubView wrapper


  ###*
   * Called when the Add New button is clicked (the one to actually
   * confirm the submission, not show the new snapshot input form)
  ###
  handleAddNew: ->

    machine   = @getData()
    machineId = machine._id
    label     = @addInputView.getValue()
    if not label? or label is ''
      @addNewButton.hideLoader()
      return MachineSettingsSnapshotsView.notify \
        'Name length must be larger than zero'

    # Get the unique label, based on our currently loaded Snapshots
    labels = (i.getData().label for i in @listController.getItemsOrdered())
    label  = snapshotHelpers.getUniqueLabel label, labels

    # Get the IDE view.
    openIdeByMachine machine, (err, ideController) =>
      if err
        @addNewButton.hideLoader()
        @showNotification 'Error, unable to create snapshot.', 'error'
        kd.error 'Unable to create snapshot, IDE Could not be found', err
        return

      container = ideController?.getView()

      unless container?
        @addNewButton.hideLoader()
        @showNotification 'Error, unable to create snapshot.', 'error'
        return kd.error 'Unable to create snapshot, IDE View could not be found'

      @emit 'ModalDestroyRequested'
      modal = snapshotHelpers.showSnapshottingModal machine, container

      @on 'SnapshotProgress', modal.bound 'updatePercentage'
      # Deferring here helps ensure that the IDE has made the proper
      # calls that it needs, before we change the machine's state to
      # Snapshotting.
      #
      # FIXME:
      kd.utils.defer => @createSnapshot label, (err, snapshot) =>
        @off 'SnapshotProgress', modal.bound 'updatePercentage'
        if err
          kd.warn err
          modal.updatePercentage 0
          return modal.showError()

        modal.destroy()
        kd.singletons.router.handleRoute "/Machines/#{machine.uid}/Snapshots"


  ###*
   * Triggered when the header add new snapshot is pressed.
  ###
  hideAddView: ->

    super

    @listController.showNoItemWidget()
