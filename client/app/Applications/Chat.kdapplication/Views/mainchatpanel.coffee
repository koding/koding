class MainChatPanel extends JView

  constructor:->
    super
      cssClass : 'main-chat-panel visible'

    @registerSingleton "chatPanel", @, yes

    @conversationList = new ChatConversationListView
    @conversationListController = new ChatConversationListController
      view : @conversationList

  createConversation:(channel)->
    @conversationListController.addItem channel

  viewAppended:->
    @addSubView @conversationList
    @conversationListController.loadItems()

  show:->
    @setClass 'visible'

  hide:->
    @unsetClass 'visible'

  toggle:->
    @toggleClass 'visible'

  isVisible:->
    @hasClass 'visible'
