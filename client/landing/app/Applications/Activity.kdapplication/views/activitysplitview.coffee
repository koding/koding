class ActivitySplitView extends SplitView

  # until mixins are here
  viewAppended : ContentPageSplitBelowHeader::viewAppended

  toggleFirstPanel: ContentPageSplitBelowHeader::toggleFirstPanel

  setRightColumnClass: ContentPageSplitBelowHeader::setRightColumnClass

  _windowDidResize:()=>
    super
    welcomeHeaderHeight = @$().siblings('h1').outerHeight()
    # updateWidgetHeight  = @$().siblings('.activity-update-widget-wrapper').outerHeight()  # split margin top

    @$().css
      marginTop : 77 # updateWidgetHeight
      height    : @parent.getHeight() - welcomeHeaderHeight - 77

