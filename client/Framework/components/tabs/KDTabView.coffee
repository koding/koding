class KDTabView extends KDTabViewController
  constructor:(options)->
    options = options ? {}
    cssClass = "kdtabview"
    cssClass += " #{options.cssClass}" if options.cssClass?
    options.cssClass = cssClass
    super options
    @_tabHandleContainerHidden = no
    @hideHandleCloseIcons() if options.hideHandleCloseIcons
    @hideHandleContainer() if options.hideHandleContainer

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
  showPane:(pane)=>
    return unless pane
    @hideAllPanes()
    pane.show()
    index = @getPaneIndex pane
    handle = @getHandleByIndex index
    handle.makeActive()
    pane.handleEvent type : "PaneDidShow"
    @handleEvent {type : "PaneDidShow", pane}
    pane

  hideAllPanes:()->
    for pane in @panes
      pane.hide()
    for handle in @handles
      handle.makeInactive()

  hideHandleContainer:()->
    @tabHandleContainer.hide()
    @_tabHandleContainerHidden = yes
  showHandleContainer:()->
    @tabHandleContainer.show()
    @_tabHandleContainerHidden = no
  toggleHandleContainer:(duration = 0)-> @tabHandleContainer.getDomElement().toggle duration

  hideHandleCloseIcons:()->
    @tabHandleContainer.getDomElement().addClass "hide-close-icons"
  showHandleCloseIcons:()->
    @tabHandleContainer.getDomElement().removeClass "hide-close-icons"
