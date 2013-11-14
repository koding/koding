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

  toggleFirstPanel:(event)->
    $panel = @panels[0].$()
    if $panel.hasClass "collapsed"
      $panel.removeClass "collapsed"
      @resizePanel 139, 0
    else
      @resizePanel 10, 0, ->
        $panel.addClass "collapsed"
    event.stopPropagation()

  _windowDidResize:->
    super
    @setRightColumnClass()

  setRightColumnClass:->
    col = @panels[1]
    col.unsetClass "extra-wide wide medium narrow extra-narrow"

    w   = col.size
    col.setClass if w > 1200 then "extra-wide"
    else if 900 < w < 1200   then "wide"
    else if 600 < w < 900    then "medium"
    else if 300 < w < 600    then "narrow"
    else "extra-narrow"
