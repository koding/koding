class ChatConversationWidget extends JView

  constructor:(item)->
    options =
      cssClass : 'inline-conversation-widget'
    super options

    @me = KD.whoami().profile.nickname
    @channel = item.getData().chatChannel

    @messageInput = new ChatInputWidget
    @messageInput.on 'messageSent', (message)=>
      @channel.publish JSON.stringify
        sender  : @me
        message : message

    @messageInput.on 'goUpRequested', =>
      item.getDelegate().goUp item

    @messageInput.on 'goDownRequested', =>
      item.getDelegate().goDown item

    @chatMessageList = new ChatMessageListView
      itemClass : ChatMessageListItem

    @chatMessageList.on 'ItemWasAdded', =>
      @expand()

    @chatMessageController = new ChatMessageListController
      view : @chatMessageList

    @channel.on 'message', @chatMessageController.bound 'addItem'

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
