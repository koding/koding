class ChatConversationWidget extends JView

  constructor:(item)->
    options =
      cssClass : 'inline-conversation-widget'

    super options

    @messageInput = new ChatInputWidget
    @messageInput.on 'messageSent', (message)=>
      @chatMessageController.addItem {message}

    @messageInput.on 'goUpRequested', =>
      item.getDelegate().goUp item

    @messageInput.on 'goDownRequested', =>
      item.getDelegate().goDown item

    @chatMessageList = new ChatMessageListView
      itemClass : ChatMessageListItem

    @chatMessageController = new ChatMessageListController
      view : @chatMessageList

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
      {{> @chatMessageList}}
      {{> @messageInput}}
    """
