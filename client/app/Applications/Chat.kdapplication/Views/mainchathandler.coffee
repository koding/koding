class MainChatHandler extends JView

  constructor:->
    super cssClass : 'main-chat-handler'

  pistachio:-> "<cite></cite>Conversations"

  viewAppended:->
    super
    (KD.getSingleton 'chatPanel').on 'PanelVisibilityChanged', (isVisible)=>
      if isVisible then @setClass 'visible'
      else @unsetClass 'visible'

  click:-> (KD.getSingleton 'chatPanel').toggle()
