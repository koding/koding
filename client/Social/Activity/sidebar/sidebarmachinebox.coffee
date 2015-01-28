class SidebarMachineBox extends KDView

  constructor: (options = {}, data) ->

    super options, data

    {machine, workspaces} = data

    machine = new KD.remote.api.JMachine machine

    @addSubView @machineItem = new NavigationMachineItem {}, machine

    @addSubView @workspacesLabel = new KDCustomHTMLView
      cssClass : 'workspaces-link'
      partial  : 'Workspaces'

    listController = new KDListViewController
      itemClass    : NavigationWorkspaceItem
      itemOptions  : { machine }

    for ws in data.workspaces
      listController.addItem ws

    @addSubView listController.getView()
