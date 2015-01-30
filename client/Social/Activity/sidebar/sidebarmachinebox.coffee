class SidebarMachineBox extends KDView

  constructor: (options = {}, data) ->

    super options, data

    { machine } = data

    @machine = new Machine machine: KD.remote.revive machine

    @addSubView @machineItem = new NavigationMachineItem {}, @machine

    @createWorkspacesLabel()
    @createWorkspacesList()


  createWorkspacesList: ->

    { machine, workspaces } = @getData()

    @listController = new KDListViewController
      itemClass     : NavigationWorkspaceItem
      itemOptions   : { machine }

    @addWorkspace ws  for ws in workspaces

    @addSubView @listController.getView()


  addWorkspace: (wsData) -> @listController.addItem wsData


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

    { machineUId, machineLabel } = @getData().machine

    @addWorkspaceView = new AddWorkspaceView {}, { machineUId, machineLabel }
    @addWorkspaceView.once 'KDObjectWillBeDestroyed', => @addWorkspaceView = null

    @listController.getView().addSubView @addWorkspaceView

    KD.utils.wait 177, => @addWorkspaceView.input.setFocus()
