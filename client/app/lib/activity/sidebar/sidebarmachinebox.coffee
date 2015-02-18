kd = require 'kd'
remote = require('app/remote').getInstance()
KDView = kd.View
KDListViewController = kd.ListViewController
KDCustomHTMLView = kd.CustomHTMLView
Machine = require '../../providers/Machine'
NavigationMachineItem = require 'app/navigation/navigationmachineitem'
SidebarWorkspaceItem = require './sidebarworkspaceitem'
MoreWorkspacesModal = require 'app/activity/sidebar/moreworkspacesmodal'
AddWorkspaceView = require 'app/addworkspaceview'


module.exports = class SidebarMachineBox extends KDView

  constructor: (options = {}, data) ->

    options.cssClass = "sidebar-machine-box #{data.machine.label}"

    super options, data

    @machine = new Machine machine: remote.revive data.machine

    @addSubView @machineItem = new NavigationMachineItem {}, @machine

    @createWorkspacesLabel()
    @createWorkspacesList()


  createWorkspacesList: ->

    { machine, workspaces } = @getData()

    @listController = new KDListViewController
      itemClass     : SidebarWorkspaceItem
      itemOptions   : { machine }

    @listWrapper = @listController.getView()

    @listController.getListView().on 'ItemWasAdded', (item) =>
      item.once 'WorkspaceDeleted', @bound 'handleWorkspaceDeleted'

    @addWorkspace ws  for ws in workspaces
    @addSubView @listWrapper

    @collapseList()


  addWorkspace: (wsData, storeData = no) ->

    @listController.addItem wsData

    return  unless storeData

    { workspaces } = @getData()
    workspaces.push wsData


  createWorkspacesLabel: ->

    @addSubView @workspacesLabel = new KDCustomHTMLView
      cssClass : 'workspaces-link'
      partial  : 'Workspaces'
      click    : =>
        modal = new MoreWorkspacesModal {}, @getData().workspaces
        modal.once 'NewWorkspaceRequested', @bound 'createAddWorkspaceInput'


  createAddWorkspaceInput: ->

    if @addWorkspaceView
      @addWorkspaceView.input.setFocus()
      return no

    data =
      machineUId   : @machine.uid
      machineLabel : @machine.label

    @addWorkspaceView = new AddWorkspaceView {}, data

    @addWorkspaceView.once 'KDObjectWillBeDestroyed', @bound 'removeAddWorkspaceInput'
    @addWorkspaceView.once 'WorkspaceCreateFailed',   @bound 'removeAddWorkspaceInput'
    @addWorkspaceView.once 'WorkspaceCreated', (ws) =>
      @addWorkspace ws, yes
      @removeAddWorkspaceInput()

    @listWrapper.addSubView @addWorkspaceView

    kd.utils.wait 177, => @addWorkspaceView.input.setFocus()


  removeAddWorkspaceInput: ->

    @addWorkspaceView.destroy()
    @addWorkspaceView = null


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

    for ws, index in workspaces when ws.getId() is wsId
      return workspaces.splice index, 1
