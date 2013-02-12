class MainTabHandleHolder extends KDView

  viewAppended:->

    mainView = @getDelegate()
    @addPlusHandle()

    mainView.mainTabView.on "PaneDidShow", (event)=> @_repositionPlusHandle event
    mainView.mainTabView.on "PaneRemoved", => @_repositionPlusHandle()

    @listenWindowResize()

  _windowDidResize:->
    mainView = @getDelegate()
    @setWidth mainView.mainTabView.getWidth() - 100

  addPlusHandle:()->

    @addSubView @plusHandle = new KDCustomHTMLView
      cssClass : 'kdtabhandle add-editor-menu visible-tab-handle plus first last'
      partial  : "<span class='icon'></span><b class='hidden'>Click here to start</b>"
      delegate : @
      click    : =>
        if @plusHandle.$().hasClass('first')
          KD.getSingleton("appManager").openApplication "StartTab"
        else
          offset = @plusHandle.$().offset()
          contextMenu = new JContextMenu
            event       : event
            delegate    : @plusHandle
            x           : offset.left - 133
            y           : offset.top + 22
            arrow       :
              placement : "top"
              margin    : -20
          ,
            'New Tab'              :
              callback             : (source, event)=>
                KD.getSingleton("appManager").tell "StartTab", 'openFreshTab'
                contextMenu.destroy()
              separator            : yes
            'Ace Editor'           :
              callback             : (source, event)=>
                KD.getSingleton("appManager").newFileWithApplication "Ace"
                contextMenu.destroy()
            'CodeMirror'           :
              callback             : (source, event)=> KD.getSingleton("appManager").notify()
            'yMacs'                :
              callback             : (source, event)=> KD.getSingleton("appManager").notify()
            'Pixlr'                :
              callback             : (source, event)=> KD.getSingleton("appManager").notify()
              separator            : yes
            'Search the App Store' :
              callback             : (source, event)=> KD.getSingleton("appManager").notify()
            'Contribute An Editor' :
              callback             : (source, event)=> KD.getSingleton("appManager").notify()


  removePlusHandle:()->
    @plusHandle.destroy()

  _repositionPlusHandle:(event)->

    appTabCount = 0
    visibleTabs = []

    for pane in @getDelegate().mainTabView.panes
      if pane.options.type is "application"
        visibleTabs.push pane
        pane.tabHandle.unsetClass "first"
        appTabCount++

    if appTabCount is 0
      @plusHandle.setClass "first last"
      @plusHandle.$('b').removeClass "hidden"
    else
      visibleTabs[0].tabHandle.setClass "first"
      @removePlusHandle()
      @addPlusHandle()
      @plusHandle.unsetClass "first"
      @plusHandle.setClass "last"
