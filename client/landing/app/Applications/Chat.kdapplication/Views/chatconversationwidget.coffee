class ChatConversationWidget extends JView

  constructor:(item)->
    super cssClass : 'inline-conversation-widget'

    @me = KD.whoami().profile.nickname
    @channel = item.getData().chatChannel

    @messageInput = new ChatInputWidget
    @messageInput.on 'messageSent', (message)=>
      @channel.publish JSON.stringify message

    @messageInput.on 'goUpRequested', =>
      item.getDelegate().goUp item

    @messageInput.on 'goDownRequested', =>
      item.getDelegate().goDown item

    @chatMessageList = new ChatMessageListView
      itemClass : ChatMessageListItem

    @chatMessageList.on 'ItemWasAdded', => @emit 'NewMessageReceived'

    @chatMessageController = new ChatMessageListController
      view    : @chatMessageList
    , item.getData()

    @chatListWrapper = @chatMessageController.getView()

    self = this
    @channel.on '*', (message)->
      self.chatMessageController.addItem @event, message

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
      {{> @chatListWrapper}}
      {{> @messageInput}}
    """
