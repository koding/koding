kd = require 'kd'
remote = require('app/remote').getInstance()
KDView = kd.View
KDListViewController = kd.ListViewController
KDCustomHTMLView = kd.CustomHTMLView
Machine = require 'app/providers/machine'
NavigationMachineItem = require 'app/navigation/navigationmachineitem'
SidebarWorkspaceItem = require './sidebarworkspaceitem'
MoreWorkspacesModal = require 'app/activity/sidebar/moreworkspacesmodal'
AddWorkspaceView = require 'app/addworkspaceview'
IDEAppController = require 'ide'
environmentDataProvider = require 'app/userenvironmentdataprovider'


module.exports = class SidebarMachineBox extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = "sidebar-machine-box #{data.machine.label}"

    super options, data

    @machine = data.machine

    unless @machine instanceof Machine
      @machine = new Machine machine: remote.revive data.machine

    @workspaceListItemsById = {}

    { workspaces } = @getData()
    machineData    = { @machine, workspaces }

    @addSubView @machineItem = new NavigationMachineItem {}, machineData

    @createWorkspacesLabel()
    @createWorkspacesList()
    @watchMachineState()

    @machine.on 'MachineLabelUpdated', @bound 'handleMachineLabelUpdated'


  createWorkspacesList: ->

    { machine, workspaces } = @getData()

    @listController = new KDListViewController
      itemClass     : SidebarWorkspaceItem
      itemOptions   : { @machine }

    @listWrapper = @listController.getView()

    @listController.getListView().on 'ItemWasAdded', (item) =>
      @workspaceListItemsById[item.getData().getId()] = item
      item.once 'WorkspaceDeleted', @bound 'handleWorkspaceDeleted'

    @addWorkspace ws  for ws in workspaces
    @addSubView @listWrapper

    @collapseList()


  getWorkspaceItemByChannelId: (channelId) ->

    items  = @listController.getListItems()
    wsitem = null

    for item in items when item.data.channelId is channelId
      wsItem = item

    return wsItem


  addWorkspace: (wsData, storeData = no) ->

    @listController.addItem wsData

    return  unless storeData

    { workspaces } = @getData()
    workspaces.push wsData


  removeWorkspace: (wsId) ->

    @listController.removeItem @workspaceListItemsById[wsId]
    @handleWorkspaceDeleted wsId

    if @getData().workspaces.length is 0
      @destroy()


  createWorkspacesLabel: ->

    @addSubView @workspacesLabel = new KDCustomHTMLView
      cssClass : 'workspaces-link'
      partial  : 'Workspaces'
      click    : =>

        return no  unless @machine.isMine()

        modal = new MoreWorkspacesModal {}, @getData().workspaces
        modal.once 'NewWorkspaceRequested', @bound 'createAddWorkspaceInput'


  createAddWorkspaceInput: ->

    if @workspaceAdditionView
      @workspaceAdditionView.input.setFocus()
      return no

    data =
      machineUId   : @machine.uid
      machineLabel : @machine.label

    @workspaceAdditionView = new AddWorkspaceView {}, data

    eventsArr = [ 'KDObjectWillBeDestroyed', 'WorkspaceCreateFailed' ]
    @workspaceAdditionView.once eventsArr, @bound 'removeAddWorkspaceInput'

    @workspaceAdditionView.once 'WorkspaceCreated', (ws) =>
      @addWorkspace ws, yes
      @removeAddWorkspaceInput()

    @listWrapper.addSubView @workspaceAdditionView

    kd.utils.wait 166, => @workspaceAdditionView.input.setFocus()


  removeAddWorkspaceInput: ->

    @workspaceAdditionView.destroy()
    @workspaceAdditionView = null


  select: -> @setClass 'selected'


  deselect: ->

    @unsetClass 'selected'

    @collapseList()
    @deselectWorkspaces()


  collapseList: ->

    return  if @isListCollapsed

    @listWrapper.setClass 'hidden'
    @workspacesLabel.setClass 'hidden'
    @isListCollapsed = yes


  expandList: ->

    @listWrapper.unsetClass 'hidden'
    @workspacesLabel.unsetClass 'hidden'
    @isListCollapsed = no


  selectWorkspace: (slug) ->

    if @machine.status.state is Machine.State.Running
      @expandList()

    @deselectWorkspaces()
    @forEachWorkspaceItem (item) ->
      if item.getData().slug is slug
        item.setClass 'selected'


  deselectWorkspaces: ->

    @forEachWorkspaceItem (item) -> item.unsetClass 'selected'


  forEachWorkspaceItem: (callback) ->

    callback item  for item in @listController.getItemsOrdered()


  handleWorkspaceDeleted: (wsId) ->

    { workspaces } = @getData()

    delete @workspaceListItemsById[wsId]

    for ws, index in workspaces when ws.getId() is wsId
      return workspaces.splice index, 1


  handleMachineLabelUpdated: (label, slug) ->

    environmentDataProvider.fetch =>
      { router, appManager, mainView } = kd.singletons

      mainView.activitySidebar.redrawMachineList()

      frontApp      = appManager.getFrontApp()
      isIDE         = frontApp.options.name is 'IDE'
      wsData        = frontApp.workspaceData
      isSameMachine = wsData.machineUId is @machine.uid

      if isIDE and wsData and isSameMachine
        router.handleRoute "/IDE/#{slug}/#{wsData.slug}"


  watchMachineState: ->

    { Stopping, Terminating, Terminated } = Machine.State

    kd.singletons.computeController.on "public-#{@machine._id}", (event) =>
      state = event.status

      return  if @latestMachineState is state

      @latestMachineState = state
      @machine.status.state = state # FIXME: why it is not setting the state itself?

      switch state
        when Stopping, Terminating then @deselect()
        when Terminated then @destroy()
