class ActivitySplitView extends SplitView

  # until mixins are here
  viewAppended : ContentPageSplitBelowHeader::viewAppended

  toggleFirstPanel: ContentPageSplitBelowHeader::toggleFirstPanel

  setRightColumnClass: ContentPageSplitBelowHeader::setRightColumnClass

  _windowDidResize:()=>
    super

    {header, widget} = @getDelegate()
    parentHeight        = @getDelegate().getHeight()
    welcomeHeaderHeight = if header then header.getHeight() else 0
    updateWidgetHeight  = if widget then widget.getHeight() else 0

    widget.$().css
      top       : welcomeHeaderHeight

    @$().css
      marginTop : updateWidgetHeight
      height    : parentHeight - welcomeHeaderHeight - updateWidgetHeight

