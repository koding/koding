class ContentPageSplitBelowHeader extends SplitViewWithOlderSiblings

  viewAppended:->
    super
    @panels[0].setClass "toggling"
    @panels[0].addSubView @_toggler = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "generic-menu-toggler"

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : @_toggler
      callback : @toggleFirstPanel

    @listenTo
      KDEventTypes : "click"
      listenedToInstance : @panels[0]
      callback : (p,e)=>
        if @panels[0].$().hasClass("collapsed")
          @toggleFirstPanel p,e

    @panels[1].on "PanelDidResize", => @setRightColumnClass()

  toggleFirstPanel:(p,e)=>
    $panel = @panels[0].$()
    if $panel.hasClass "collapsed"
      $panel.removeClass "collapsed"
      @resizePanel 139, 0
    else
      @resizePanel 10, 0, ->
        $panel.addClass "collapsed"
    e.stopPropagation()

  _windowDidResize:=>
    super
    @setRightColumnClass()

  setRightColumnClass:=>
    rightCol = @panels[1]
    rightColSize = rightCol.size
    rightCol.unsetClass "extra-wide wide medium narrow extra-narrow"

    if rightColSize > 1200
      rightCol.setClass "extra-wide"
    else if rightColSize < 1200 and rightColSize > 900
      rightCol.setClass "wide"
    else if rightColSize < 900 and rightColSize > 600
      rightCol.setClass "medium"
    else if rightColSize < 600 and rightColSize > 300
      rightCol.setClass "narrow"
    else
      rightCol.setClass "extra-narrow"
