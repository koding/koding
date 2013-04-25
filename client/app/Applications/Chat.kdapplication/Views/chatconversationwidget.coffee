class ChatConversationWidget extends JView

  constructor:(item)->
    options =
      cssClass : 'inline-conversation-widget'

    super options

    @messageInput = new ChatInputWidget
    @messageInput.on 'messageSent', (message)=>
      @conversationController.addItem {message}

    @messageInput.on 'goUpRequested', =>
      item.getDelegate().goUp item

    @messageInput.on 'goDownRequested', =>
      item.getDelegate().goDown item

    @conversationList = new ChatMessageListView
      itemClass : ChatMessageListItem

    @conversationController = new ChatMessageListController
      view : @conversationList

  toggle:->
    @toggleClass 'ready'

  collapse:->
    @unsetClass 'ready'

  expand:->
    @setClass 'ready'
    @takeFocus()

  isVisible:->
    @hasClass 'ready'

  takeFocus:->
    @messageInput.setFocus()

  pistachio:->
    """
      {{> @conversationList}}
      {{> @messageInput}}
    """
