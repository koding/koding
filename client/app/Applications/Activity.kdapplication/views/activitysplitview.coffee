class ActivitySplitView extends SplitView

  constructor:(options = {}, data)->

    options.sizes     or= [139,null]
    options.minimums  or= [10,null]
    options.resizable or= no

    super options, data

  # until mixins are here
  viewAppended : ContentPageSplitBelowHeader::viewAppended

  toggleFirstPanel: ContentPageSplitBelowHeader::toggleFirstPanel

  setRightColumnClass: ContentPageSplitBelowHeader::setRightColumnClass

  _windowDidResize:()=>
    super

    {header, widget} = @getDelegate()
    parentHeight        = @getDelegate().getHeight()
    welcomeHeaderHeight = if header.$().is ":visible" then header.getHeight() else 0
    updateWidgetHeight  = if widget.$().is ":visible" then widget.getHeight() else 0

    widget?.$().css
      top       : welcomeHeaderHeight

    @$().css
      marginTop : updateWidgetHeight
      height    : parentHeight - welcomeHeaderHeight - updateWidgetHeight

