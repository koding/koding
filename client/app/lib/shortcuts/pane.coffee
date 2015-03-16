kd = require 'kd'
ShortcutsListItem = require './list-item'
ListHead = require './list-head'

module.exports =

class ShortcutsModalPane extends kd.View

  constructor: (options={}, data) ->

    options.cssClass = 'shortcuts-pane'
    @collection = data.collection
    @title = data.title
    @description = data.description
    super options, data


  viewAppended: ->

    #@addSubView @searchField = new kd.InputView
      #placeholder : 'Search'
      #cssClass    : 'search-input'
      #keyup       : kd.noop
      ##keyup       : kd.utils.debounce 300, @bound 'search'

    #@addSubView new kd.CustomHTMLView
      #tagName  : 'cite'
      #cssClass : 'search-icon'

    #@searchField.setFocus()

    @addSubView new ListHead
      cssClass: 'list-head'
      description: @description
    
    @listController = new kd.ListViewController
      useCustomScrollView : no
      viewOptions         :
        itemClass         : ShortcutsListItem

    @collection.each (model) =>
      @listController.addItem
        name: model.description

    @addSubView @listController.getView()
