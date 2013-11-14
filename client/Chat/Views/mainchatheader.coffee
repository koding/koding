class MainChatHeader extends JView

  constructor:->
    super
      cssClass : 'main-chat-header'

    chatPanel = KD.getSingleton "chatPanel"

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
          chatPanel.toggleInboxMode()
          callback?()
      ,
        title         : "hide"
        iconClass     : "right"
        callback      : (callback)->
          chatPanel.toggleInboxMode()
          callback?()
      ]

    @pinPanelButton = new KDToggleButton
      style           : "panel-pinner"
      iconOnly        : yes
      defaultState    : "pin"
      states          : [
        title         : "pin"
        iconClass     : "left"
        callback      : (callback)->
          contentPanel = KD.getSingleton('contentPanel')
          contentPanel.chatMargin = 250
          contentPanel._windowDidResize()
          callback?()
      ,
        title         : "unpin"
        iconClass     : "right"
        callback      : (callback)->
          contentPanel = KD.getSingleton('contentPanel')
          contentPanel.chatMargin = 0
          contentPanel._windowDidResize()
          chatPanel.hidePanel()
          callback?()
      ]

  pistachio:->
    """
      {{> @pinPanelButton}}
      {{> @header}}
      {{> @newConversationButton}}
    """
