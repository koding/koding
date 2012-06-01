class FeederTabView extends KDTabView
  constructor:(options = {}, data)->
    options.cssClass or= "feeder-tabs"
    super options, data

  _windowDidResize:->
    super
    for pane in @panes
      pane.listWrapper.setHeight @getHeight() - pane.listHeader.getHeight()

class FeederTabPaneView extends KDTabPaneView
      
  newItemArrived:()->
    log arguments