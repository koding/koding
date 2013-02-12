class StartTabAppController extends AppController

  constructor:->
    super
    @openTabs = []

  bringToFront:->
    frontTab = if !@openTabs.length then @createNewTab() else @openTabs[@openTabs.length - 1]

    # @propagateEvent
    #   KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    # ,
    #   options:
    #     hiddenHandle  : no
    #     type          : 'application'
    #     name          : 'New Tab'
    #     controller    : @
    #   data : frontTab

    @emit 'ApplicationWantsToBeShown', @, frontTab,
      hiddenHandle  : no
      type          : 'application'
      name          : 'New Tab'

    # @setViewListeners frontTab

  # setViewListeners:(view)->
  #   view.on 'ViewClosed', =>
  #     @removeOpenTab view
  #     @propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent: yes), data : view
  #     view.destroy()

  createNewTab:->
    appController = @
    tab = new StartTabMainView delegate  : @
    tab.on 'ViewClosed', => @closeTab tab
    @addOpenTab tab
    return tab

  addOpenTab:(tab)->
    KD.getSingleton("appManager").addOpenTab tab, @
    @openTabs.push tab

  removeOpenTab:(tab)->
    KD.getSingleton("appManager").removeOpenTab tab
    @openTabs.splice (@openTabs.indexOf tab), 1

  openFreshTab:->
    frontTab = @createNewTab()

    @emit 'ApplicationWantsToBeShown', @, frontTab,
      hiddenHandle  : no
      type          : 'application'
      name          : 'New Tab'

    # @propagateEvent
    #   KDEventType : 'ApplicationWantsToBeShown', globalEvent : yes
    # ,
    #   options:
    #     hiddenHandle  : no
    #     type          : 'application'
    #     name          : 'New Tab'
    #     controller    : @
    #   data : frontTab

  closeTab: (tab) ->
    appController = @getDelegate() or @
    appController.removeOpenTab tab
    # appController.propagateEvent (KDEventType : 'ApplicationWantsToClose', globalEvent: yes), data : tab
    appController.emit 'ApplicationIsBeingClosed', @, tab

    tab.destroy()

  @getName: ->
    'startTab'
