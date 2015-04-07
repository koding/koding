kd = require 'kd'
ShortcutsListController = require './listcontroller'
ListHead = require './listhead'

module.exports =

class ShortcutsModalPane extends kd.View

  constructor: (options={}, data) ->

    options.cssClass = 'shortcuts-pane'

    @collection  = options.collection
    @description = options.description

    super options, data


  viewAppended: ->

    @addSubView @listHead = new ListHead
      cssClass: 'list-head'
      description: @description

    @listController = new ShortcutsListController

    @collection.each (model) =>
      @listController.addItem model

    @addSubView @listController.getView()
