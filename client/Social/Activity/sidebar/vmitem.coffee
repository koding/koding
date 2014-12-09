class SidebarVMItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.attributes = {}

    super

    @machine = new Machine {machine: data}


  pistachio: ->
    """
      #{@machine.slug ? "koding-vm-0"}
    """

