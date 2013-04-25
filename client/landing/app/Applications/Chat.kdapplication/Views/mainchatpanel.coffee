class MainChatPanel extends JView

  constructor:->
    super
      cssClass : 'main-chat-panel'

    @registerSingleton "chatPanel", @, yes

    @conversationList = new ChatConversationListView
    @conversationListController = new ChatConversationListController
      view : @conversationList

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
