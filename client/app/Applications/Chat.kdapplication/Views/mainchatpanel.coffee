class MainChatPanel extends JView

  constructor:->
    super
      cssClass : 'main-chat-panel hidden'

    @registerSingleton "chatPanel", @, yes

    @header = new MainChatHeader

    @warningWidget = new KDView
      cssClass : 'warning-widget'
      partial  : """Conversations are under construction, you can still
                    send and receive messages from other Koding users
                    but these messages will not be saved."""

    @conversationList = new ChatConversationListView
    @conversationListController = new ChatConversationListController
      view : @conversationList

    @on 'PanelVisibilityChanged', (visible)=>
      if visible
        KD.getSingleton('windowController').addLayer @
        @once 'ReceivedClickElsewhere', (event)=>
          unless $(event.target).closest('.main-chat-handler').length > 0 or\
                 $(event.target).closest('.kdlistitemview-default.chat').length > 0
            @hidePanel()

    # FIXME Later ~ GG
    mainController = KD.getSingleton("mainController")
    mainController.on "accountChanged.to.loggedIn", =>
      @conversationListController.loadItems()
      # @showPanel()

  createConversation:(data)->
    # Data includes chatChannel and the conversation
    @conversationListController.addItem data

  viewAppended:->
    @addSubView @header
    @addSubView @conversationList
    @addSubView @warningWidget

    @conversationListController.loadItems()
    # @showPanel()  if KD.isLoggedIn()

  showPanel:->
    # return  unless KD.isLoggedIn()

    @show()
    @utils.defer =>
      @setClass 'visible'
      @emit 'PanelVisibilityChanged', true

  hidePanel:->
    contentPanel = KD.getSingleton('contentPanel')
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
      {winWidth} = KD.getSingleton('windowController')
      @setWidth winWidth - 160
      @toggleClass 'inbox-mode'
      @inboxMode = yes
    else
      @toggleClass 'inbox-mode'
      @setWidth 250
      @inboxMode = no

    @listenWindowResize @inboxMode

  _windowDidResize:->
    {winWidth} = KD.getSingleton('windowController')
    @setWidth winWidth - 160
