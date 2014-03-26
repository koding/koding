class MainTabHandleHolder extends KDView

  constructor: (options = {}, data) ->

    options.bind = "mouseenter mouseleave"

    super options, data

    @userApps = []

  viewAppended:->

    mainView = @getDelegate()
    @addPlusHandle()

    mainView.mainTabView.on "PaneDidShow", (event)=> @_repositionPlusHandle event
    mainView.mainTabView.on "PaneRemoved", => @_repositionPlusHandle()

    mainView.mainTabView.on "PaneAdded", (pane) =>
      tabHandle = pane.tabHandle

      tabHandle.on "DragStarted", =>
        tabHandle.dragIsAllowed = if @subViews.length <= 2 then no else yes
      tabHandle.on "DragInAction", =>
        @plusHandle.hide() if tabHandle.dragIsAllowed
      tabHandle.on "DragFinished", =>
        @plusHandle.show()

    @listenWindowResize()

  _windowDidResize:->
    mainView = @getDelegate()
    @setWidth mainView.mainTabView.getWidth()

  addPlusHandle:->

    @addSubView @plusHandle = new KDCustomHTMLView
      cssClass : 'kdtabhandle add-editor-menu visible-tab-handle plus first last'
      partial  : "<span class='icon'></span><b class='hidden'>Click here to start</b>"
      delegate : @
      click    : @bound "createPlusHandleDropDown"

  createPlusHandleDropDown:(event)->

    appsController = KD.getSingleton "kodingAppsController"
    appManager     = KD.getSingleton "appManager"

    if @plusHandle.$().hasClass('first')
      KD.getSingleton("appManager").open "StartTab"
    else
      offset = @plusHandle.$().offset()
      contextMenu = new KDContextMenu
        event       : event
        delegate    : @plusHandle
        x           : offset.left - 133
        y           : offset.top + 22
        arrow       :
          placement : "top"
          margin    : -20
      ,
        'Your Apps'            :
          callback             : (source, event) ->
            appManager.open "StartTab", forceNew : yes
            contextMenu.destroy()
          separator            : yes
        'Ace Editor'           :
          callback             : (source, event) ->
            appManager.open "Ace", forceNew : yes
            contextMenu.destroy()
        'Terminal'             :
          callback             : (source, event) ->
            appManager.open "Terminal", forceNew : yes
            contextMenu.destroy()
        'Teamwork'             :
          callback             : ->
            KD.getSingleton("router").handleRoute "/Develop/Teamwork"
            contextMenu.destroy()
          separator            : yes
        'Search the App Store' :
          callback             : (source, event) ->
            appManager.open "Apps"
            contextMenu.destroy()
        'Make your own app...' :
          callback             : (source, event)=> appsController.makeNewApp()

      index = 4
      appsController.fetchApps (err, apps)=>
        for own name, app of apps
          app.callback = appManager.open.bind appManager, name, {forceNew : yes}, contextMenu.bound("destroy")
          app.title    = name
          contextMenu.treeController.addNode app, index
          index++

  removePlusHandle:->
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
