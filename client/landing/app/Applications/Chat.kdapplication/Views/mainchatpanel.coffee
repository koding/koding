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
