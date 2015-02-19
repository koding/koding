JView = require '../../jview'
Machine = require '../../providers/machine'
SidebarItem = require './sidebaritem'


module.exports = class SidebarVMItem extends SidebarItem

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.attributes = {}

    super

    @machine = new Machine {machine: data}


  pistachio: ->
    """
      #{@machine.slug ? "koding-vm-0"}
    """



