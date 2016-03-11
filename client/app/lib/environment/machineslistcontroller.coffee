kd                     = require 'kd'
MachinesListItemHeader = require './machineslistitemheader'


module.exports = class MachinesListController extends kd.ListViewController

  constructor: (options = {}, data) ->

    options.headerItemClass ?= MachinesListItemHeader

    super options, data


  instantiateListItems: (items) ->

    @getListView().addItemView new (@getOption 'headerItemClass')

    super items
