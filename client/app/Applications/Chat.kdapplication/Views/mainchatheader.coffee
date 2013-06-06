class MainChatHeader extends JView

  constructor:->
    super
      cssClass : 'main-chat-header'

    @header = new HeaderViewSection
      type    : "big"
      title   : "Conversations"

    @newConversationButton = new ConversationStarterButton

    @viewChangeButton = new KDToggleButton
      style           : "clean-gray view-changer"
      iconOnly        : yes
      defaultState    : "show"
      states          : [
        title         : "show"
        iconClass     : "left"
        callback      : (callback)->
          KD.singletons.chatPanel.toggleInboxMode()
          callback?()
      ,
        title         : "hide"
        iconClass     : "right"
        callback      : (callback)->
          KD.singletons.chatPanel.toggleInboxMode()
          callback?()
      ]

  pistachio:->
    """
      {{> @header}}
      {{> @newConversationButton}}
      {{> @viewChangeButton}}
    """
