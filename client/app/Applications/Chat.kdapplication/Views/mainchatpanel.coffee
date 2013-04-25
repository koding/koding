class MainChatPanel extends JView

  constructor:->
    super
      cssClass : 'main-chat-panel'

    @registerSingleton "chatPanel", @, yes

    @contactList = new ChatContactListView
    @contactListController = new ChatContactListController
      view : @contactList

  viewAppended:->
    @addSubView @contactList
    @contactListController.loadItems()

  show:->
    @setClass 'visible'

  hide:->
    @unsetClass 'visible'

  toggle:->
    @toggleClass 'visible'

  isVisible:->
    @hasClass 'visible'
