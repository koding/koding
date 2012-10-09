class BottomChatPanel extends BottomPanel

  constructor:->

    super

    @splitWrapper = new KDScrollView
      cssClass : "split-wrapper"

    @splitWrapper.addSubView @split = new SlidingSplit
      cssClass : "chat-split"
      sizes    : [null]

    @sidebar = new BottomChatSideBar
      cssClass : "chat-sidebar"

    @split.on "SplitPanelCreated", (panel)=>
      panel.addSubView new BottomChatRoom

  viewAppended:JView::viewAppended

  _windowDidResize:->

    super

    @utils.wait 300, =>
      @splitWrapper.setWidth @getWidth() - 150

  pistachio:->

    """
      {{> @sidebar}}
      {{> @splitWrapper}}
    """


