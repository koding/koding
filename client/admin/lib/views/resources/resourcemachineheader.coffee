kd                     = require 'kd'
MachinesListItemHeader = require 'app/environment/machineslistitemheader'


module.exports = class ResourceMachineHeader extends MachinesListItemHeader

  pistachio: ->
    """
      <div>NAME</div>
      <div>PROVIDER</div>
      <div>TYPE</div>
      <div>OS</div>
      <div class='input-title'>ALWAYS ON</div>
    """
