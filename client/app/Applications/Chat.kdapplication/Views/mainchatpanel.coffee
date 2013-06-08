class MainChatPanel extends JView

  constructor:->
    super
      cssClass : 'main-chat-panel hidden'

    @registerSingleton "chatPanel", @, yes

    @header = new MainChatHeader

    @conversationList = new ChatConversationListView
    @conversationListController = new ChatConversationListController
      view : @conversationList

    @on 'PanelVisibilityChanged', (visible)=>
      if visible
        @getSingleton('windowController').addLayer @
        @once 'ReceivedClickElsewhere', @bound 'hidePanel'

    # FIXME Later ~ GG
    {mainController} = KD.singletons
    mainController.on "accountChanged.to.loggedIn", =>
      @conversationListController.loadItems()
      @showPanel()

  createConversation:(data)->
    # Data includes chatChannel and the conversation
    @conversationListController.addItem data

  viewAppended:->
    @addSubView @header
    @addSubView @conversationList
    @conversationListController.loadItems()
    @showPanel()  if KD.isLoggedIn()

  showPanel:->
    return  unless KD.isLoggedIn()

    @show()
    @utils.defer =>
      @setClass 'visible'
      @emit 'PanelVisibilityChanged', true

  hidePanel:->
    contentPanel = @getSingleton('contentPanel')
    return  if contentPanel.chatMargin is 250

    @unsetClass 'visible'
    @utils.defer =>
      @emit 'PanelVisibilityChanged', false
      @utils.wait 400, => @hide()

  toggle:-> if @isVisible() then @hidePanel() else @showPanel()

  isVisible:->
    @hasClass 'visible'

  toggleInboxMode:->
    if @getWidth() is 250
      {winWidth} = @getSingleton('windowController')
      @setWidth winWidth - 160
      @toggleClass 'inbox-mode'
      @inboxMode = yes
    else
      @toggleClass 'inbox-mode'
      @setWidth 250
      @inboxMode = no

    @listenWindowResize @inboxMode

  _windowDidResize:->
    {winWidth} = @getSingleton('windowController')
    @setWidth winWidth - 160
