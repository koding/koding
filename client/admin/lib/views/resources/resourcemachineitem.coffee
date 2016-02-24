kd               = require 'kd'
MachinesListItem = require 'app/environment/machineslistitem'

module.exports = class ResourceMachineItem extends MachinesListItem

  createSidebarToggle: ->
    @sidebarToggle = new kd.CustomHTMLView
