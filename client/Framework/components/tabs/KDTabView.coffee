class KDTabView extends KDTabViewController

  constructor:(options = {})->

    super options

    @setClass "kdtabview"

    @handlesHidden = no

    @hideHandleCloseIcons() if options.hideHandleCloseIcons
    @hideHandleContainer()  if options.hideHandleContainer

  appendHandleContainer:()->
    @addSubView @tabHandleContainer

  appendPane:(pane)->
    pane.setDelegate @
    @addSubView pane

  appendHandle:(tabHandle)->
    @handleHeight or= @tabHandleContainer.getHeight()
    tabHandle.setDelegate @
    @tabHandleContainer.addSubView tabHandle
    # unless tabHandle.options.hidden
    #   tabHandle.$().css {marginTop : @handleHeight}
    #   tabHandle.$().animate({marginTop : 0},300)

  #SHOW/HIDE ELEMENTS
  showPane:(pane)->
    return unless pane
    @hideAllPanes()
    pane.show()
    index = @getPaneIndex pane
    handle = @getHandleByIndex index
    handle.makeActive()
    pane.emit "PaneDidShow"
    @emit "PaneDidShow", pane
    pane

  hideAllPanes:()->
    for pane in @panes
      pane.hide()
    for handle in @handles
      handle.makeInactive()

  hideHandleContainer:()->

    @tabHandleContainer.hide()
    @handlesHidden = yes

  showHandleContainer:()->

    @tabHandleContainer.show()
    @handlesHidden = no

  toggleHandleContainer:(duration = 0)->
    @tabHandleContainer.$().toggle duration

  hideHandleCloseIcons:()->
    @tabHandleContainer.$().addClass "hide-close-icons"

  showHandleCloseIcons:()->
    @tabHandleContainer.$().removeClass "hide-close-icons"
