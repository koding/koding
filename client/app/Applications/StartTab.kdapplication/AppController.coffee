class StartTab12345 extends AppController

  bringToFront:->
    frontTab = if !@openTabs.length then @createNewTab() else @openTabs[@openTabs.length - 1]

    @propagateEvent
      KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    ,
      options:
        hiddenHandle  : no
        type          : 'application'
        name          : 'New Tab'
        controller    : @
      data : frontTab

    @setViewListeners frontTab

  initAndBringToFront:(options,callback)->
    @initApplication options, =>
      @bringToFront()
      callback()

  initApplication:(options, callback)=>
    @openTabs       = []
    @_storage       = no
    # log 'init application called'
    notification    = no

    callback()

    @setViewListeners()

  setViewListeners:(view)->
    @listenTo
      KDEventTypes       : 'ViewClosed',
      listenedToInstance : view
      callback           : (tab)=>
        @removeOpenTab tab
        @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent: yes), data : tab
        tab.destroy()

  createNewTab:->
    appController = @
    tab = new StartTabMainView
      delegate  : @
    # tab.listenTo KDEventTypes:'ViewClosed', callback:@closeTab
    @addOpenTab tab

    tab

  addOpenTab:(tab)->
    appManager.addOpenTab tab, @
    @openTabs.push tab

  removeOpenTab:(tab)->
    appManager.removeOpenTab tab
    @openTabs.splice (@openTabs.indexOf tab), 1

  openFreshTab:->
    frontTab = @createNewTab()

    @propagateEvent
      KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    ,
      options:
        hiddenHandle  : no
        type          : 'application'
        name          : 'New Tab'
        controller    : @
      data : frontTab

  closeTab: (tab) ->
    appController = @getDelegate() or @
    appController.removeOpenTab tab
    appController.propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent: yes), data : tab

    tab.destroy()

  @getName: ->
    'startTab'
