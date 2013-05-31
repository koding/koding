class MainChatPanel extends JView

  constructor:->
    super
      cssClass : 'main-chat-panel'

    @registerSingleton "chatPanel", @, yes

    @header = new MainChatHeader
    @conversationList = new ChatConversationListView
    @conversationListController = new ChatConversationListController
      view : @conversationList

  createConversation:(channel)->
    @conversationListController.addItem channel

  viewAppended:->
    @addSubView @header
    @addSubView @conversationList
    @conversationListController.loadItems()

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
