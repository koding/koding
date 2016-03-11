kd               = require 'kd'
MachinesListItem = require './machineslistitem'


module.exports = class MachinesList extends kd.ListView

  constructor: (options = {}, data) ->

    options.itemClass ?= MachinesListItem
    options.cssClass   = kd.utils.curry 'machines-list', options.cssClass

    super options, data
