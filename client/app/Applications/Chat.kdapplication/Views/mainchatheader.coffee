class MainChatHeader extends JView

  constructor:->
    super
      cssClass : 'main-chat-header'

    @header = new HeaderViewSection
      type    : "big"
      title   : "Conversations"

    @newConversationButton = new ConversationStarterButton

  viewAppended:->
    @addSubView @header
    @addSubView @newConversationButton