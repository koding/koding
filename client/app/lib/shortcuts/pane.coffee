kd = require 'kd'
ShortcutsListItem = require './listitem'

module.exports =

class ShortcutsModalPane extends kd.CustomHTMLView

  constructor: (options={}, data) ->

    super options, data


  viewAppended: ->

    @addSubView @searchField = new kd.InputView
      placeholder : 'Search'
      cssClass    : 'search-input'
      keyup       : kd.noop
      #keyup       : kd.utils.debounce 300, @bound 'search'

    @addSubView new kd.CustomHTMLView
      tagName  : 'cite'
      cssClass : 'search-icon'

    @searchField.setFocus()

    @listController = new kd.ListViewController
      useCustomScrollView : no
      viewOptions         :
        type              : 'activities'
        itemClass         : ShortcutsListItem
        cssClass          : 'activities topics-list'

    @data.each (model) =>
      @listController.addItem
        name: model.description

    @addSubView @listController.getView()
