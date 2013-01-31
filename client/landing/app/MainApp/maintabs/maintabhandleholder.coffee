class MainTabHandleHolder extends KDView

  viewAppended:->

    mainView = @getDelegate()
    @addPlusHandle()

    mainView.mainTabView.on "PaneDidShow", (event)=> @_repositionPlusHandle event
    mainView.mainTabView.on "PaneRemoved", => @_repositionPlusHandle()

    @listenWindowResize()

  click:(event)->
    @_plusHandleClicked() if $(event.target).closest('.kdtabhandle').is('.plus')

  _windowDidResize:->
    mainView = @getDelegate()
    @setWidth mainView.mainTabView.getWidth()

  addPlusHandle:()->

    @addSubView @plusHandle = new KDCustomHTMLView
      cssClass : 'kdtabhandle add-editor-menu visible-tab-handle plus first last'
      partial  : "<span class='icon'></span><b class='hidden'>Click here to start</b>"
      delegate : @
      click    : =>
        unless @plusHandle.$().hasClass('first')
          contextMenu = new JContextMenu
            event    : event
            delegate : @plusHandle
          ,
            'New Tab'              :
              callback             : (source, event)=>
                appManager.tell "StartTab", 'openFreshTab'
                contextMenu.destroy()
              separator            : yes
            'Ace Editor'           :
              callback             : (source, event)=>
                appManager.newFileWithApplication "Ace"
                contextMenu.destroy()
            'CodeMirror'           :
              callback             : (source, event)=> appManager.notify()
            'yMacs'                :
              callback             : (source, event)=> appManager.notify()
            'Pixlr'                :
              callback             : (source, event)=> appManager.notify()
              separator            : yes
            'Search the App Store' :
              callback             : (source, event)=> appManager.notify()
            'Contribute An Editor' :
              callback             : (source, event)=> appManager.notify()


  removePlusHandle:()->
    @plusHandle.destroy()

  _plusHandleClicked: () ->
    if @plusHandle?.__shouldAdd
      @plusHandle.delegate.propagateEvent KDEventType : 'AddEditorClick', @plusHandle
      # appManager.newFileWithApplication "Ace"
    else
      appManager.openApplication "StartTab"
      # @getSingleton('router').handleRoute "/Develop"

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
      @plusHandle.__shouldAdd = no
    else
      visibleTabs[0].tabHandle.setClass "first"
      @removePlusHandle()
      @addPlusHandle()
      @plusHandle.unsetClass "first"
      @plusHandle.setClass "last"
      @plusHandle.__shouldAdd = yes
