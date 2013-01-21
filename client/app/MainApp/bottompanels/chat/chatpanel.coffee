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
      panel.addSubView panel.room = new BottomChatRoom
      
      panel.room.tokenInput.on "chat.ui.inputReceivedClick", =>
        @split.setFocusedPanel panel

      panel.room.tokenInput.on "chat.ui.changeFocus", (keyCode)=>
        #keypress is unavoidable at this point
        switch keyCode
          when 37 then do @split.focusPrevPanel
          when 39 then do @split.focusNextPanel
          else
            @split.focusByIndex i if 0 <= (i = e.which - 49) < 10
      
      panel.room.tokenInput.on "chat.ui.splitPanel", =>
        @split.splitPanel()

    @split.on "PanelIsFocused", (panel)=>
      panel.room.tokenInput.input.$().trigger "focus"

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


