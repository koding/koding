class FeederTabView extends KDTabView

  constructor:(options = {}, data)->

    options.cssClass or= "feeder-tabs"

    super options, data

    @listenWindowResize()
    @unsetClass "kdscrollview"

  _windowDidResize:->
    super
    h = @getHeight()
    for pane in @panes
      {listWrapper, listHeader} = pane
      listWrapper.setHeight h - listHeader.getHeight()