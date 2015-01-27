class SidebarMachineBox extends KDView

  constructor: (options = {}, data) ->

    super options, data


    {machine, workspaces} = data

    machine = new KD.remote.api.JMachine machine

    @addSubView new NavigationMachineItem {}, machine

