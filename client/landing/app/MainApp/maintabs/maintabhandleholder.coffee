class MainTabHandleHolder extends KDView
  viewAppended:->
    mainView = @getDelegate()
    @addPlusHandle()
        
    @listenTo
      KDEventTypes : ["PaneDidShow","PaneRemoved"]
      listenedToInstance : mainView.mainTabView
      callback: @_repositionPlusHandle
      
    @listenWindowResize()
  
  click:(event)->
    @_plusHandleClicked() if $(event.target).closest('.kdtabhandle').is('.plus')

  _windowDidResize:->
    mainView = @getDelegate()
    @setWidth mainView.mainTabView.getWidth() - 100

  addPlusHandle:()->
    menu =
      type : "contextmenu"
      items : [
        { title : 'New Tab',              id : 1,  parentId : null, callback:(source, event)=> appManager.tell "StartTab", 'openFreshTab'}
        { type  : 'divider' }
        { title : 'Ace Editor',           id : 2,  parentId : null, callback:(source, event)=> appManager.newFileWithApplication "Ace"}
        { title : 'CodeMirror',           id : 3,  parentId : null, callback:(source, event)=> appManager.notify() }
        { title : 'yMacs',                id : 4,  parentId : null, callback:(source, event)=> appManager.notify() }
        { title : 'Pixlr',                id : 5,  parentId : null, callback:(source, event)=> appManager.notify() }
        { type  : 'divider' }
        { title : 'Search the App Store', id : 6,  parentId : null, callback:(source, event)=> appManager.notify() }
        { title : 'Contribute An Editor', id : 7,  parentId : null, callback:(source, event)=> appManager.notify() }
      ]
      
    @addSubView @plusHandle = new KDCustomHTMLView
      cssClass : 'kdtabhandle add-editor-menu visible-tab-handle plus first last'
      partial  : "<b class='hidden'>Click here to start</b>"
      delegate : @
      # menu     : [menu]
      # callback : => (event)-> splitButton.contextMenu event
    
  removePlusHandle:()->
    @plusHandle.destroy()
  
  _plusHandleClicked: () ->
    if @plusHandle?.__shouldAdd
      @plusHandle.delegate.propagateEvent KDEventType : 'AddEditorClick', @plusHandle
      # appManager.newFileWithApplication "Ace"
    else
      appManager.openApplication "StartTab"
  
  _repositionPlusHandle:(pubInst,event)->
    appTabCount = 0
    visibleTabs = []
    for pane in pubInst.panes
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
