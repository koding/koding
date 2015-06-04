kd                     = require 'kd'
MachinesListItemHeader = require './machineslistitemheader'


module.exports = class MachinesListController extends kd.ListViewController

  instantiateListItems: (items) ->

    @getListView().addItemView new MachinesListItemHeader

    super items
