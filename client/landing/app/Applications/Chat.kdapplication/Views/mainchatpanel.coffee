class MainChatPanel extends JView

  constructor:->
    super
      cssClass : 'main-chat-panel'

    @registerSingleton "chatPanel", @, yes

    @header = new MainChatHeader

    @conversationList = new ChatConversationListView
    @conversationListController = new ChatConversationListController
      view : @conversationList

    @on 'PanelVisibilityChanged', (visible)=>
      if visible
        @getSingleton('windowController').addLayer @
        @once 'ReceivedClickElsewhere', @bound 'hide'

  createConversation:(data)->
    # Data includes chatChannel and the conversation
    @conversationListController.addItem data

  viewAppended:->
    @addSubView @header
    @addSubView @conversationList
    @conversationListController.loadItems()
    @show()

  show:->
    @setClass 'visible'
    @emit 'PanelVisibilityChanged', true

  hide:->
    @unsetClass 'visible'
    @emit 'PanelVisibilityChanged', false

  toggle:->
    @toggleClass 'visible'
    @emit 'PanelVisibilityChanged', @isVisible()

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
