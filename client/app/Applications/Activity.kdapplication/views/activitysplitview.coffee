class ActivitySplitView extends SplitView

  # until mixins are here
  viewAppended : ContentPageSplitBelowHeader::viewAppended

  toggleFirstPanel: ContentPageSplitBelowHeader::toggleFirstPanel

  setRightColumnClass: ContentPageSplitBelowHeader::setRightColumnClass

  _windowDidResize:()=>
    super
    welcomeHeaderHeight = @$().siblings('h1').outerHeight(no)
    # updateWidgetHeight  = @$().siblings('.activity-update-widget-wrapper').outerHeight(no)  # split margin top
    log @, @parent.getHeight() - 77 - (welcomeHeaderHeight or 0)
    @$().css
      marginTop : 77 # updateWidgetHeight
      height    : @parent.getHeight() - (welcomeHeaderHeight or 0) - 77

