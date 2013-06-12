class MainChatHandler extends JView

  constructor:->
    super cssClass : 'main-chat-handler'
    @panel = (KD.getSingleton 'chatPanel')
  pistachio:-> "<cite></cite>Conversations"

  viewAppended:->
    super
    @panel.on 'PanelVisibilityChanged', (isVisible)=>
      if isVisible then @setClass 'visible'
      else @unsetClass 'visible'

  click:-> @panel.toggle()
