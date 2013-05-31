class ChatConversationWidget extends JView

  constructor:(item)->
    super cssClass : 'inline-conversation-widget'

    @me = KD.whoami().profile.nickname
    @channel = item.getData().chatChannel

    @messageInput = new ChatInputWidget {}, item.getData()

    @messageInput.on 'goUpRequested', =>
      item.getDelegate().goUp item

    @messageInput.on 'goDownRequested', =>
      item.getDelegate().goDown item

    @chatMessageList = new ChatMessageListView
      itemClass : ChatMessageListItem

    @chatMessageList.on 'ItemWasAdded', =>
      @expand()

    @chatMessageController = new ChatMessageListController
      view    : @chatMessageList
    , item.getData()

    c = @channel
    @channel.on '*', (message)->
      log @event, message
      # FIXME ~ GG
      # @chatMessageController.addItem @channel.event, message

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
