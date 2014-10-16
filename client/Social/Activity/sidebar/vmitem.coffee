class SidebarVMItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.attributes = {}
    super

    @machine = new Machine {machine: data}

    position =
      top    : 0
      left   : 0

    @settings = new KDButtonView
      partial : 'Settings'
      callback: => new MachineSettingsPopup {position}, @machine


  pistachio: ->
    """
      #{@machine.slug}
      {{> @settings }}
    """

