class ContentPageSplitBelowHeader extends SplitViewWithOlderSiblings

  viewAppended:->

    super

    [panel0, panel1] = @panels

    panel0.setClass "toggling"
    panel0.addSubView @_toggler = new KDCustomHTMLView
      tagName  : "span"
      cssClass : "generic-menu-toggler"
      click    : @bound "toggleFirstPanel"

    panel0.on "click", (event)=>
      if panel0.$().hasClass "collapsed"
        @toggleFirstPanel event

    panel1.on "PanelDidResize", => @setRightColumnClass()

  toggleFirstPanel:(event)=>
    $panel = @panels[0].$()
    if $panel.hasClass "collapsed"
      $panel.removeClass "collapsed"
      @resizePanel 139, 0
    else
      @resizePanel 10, 0, ->
        $panel.addClass "collapsed"
    event.stopPropagation()

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
