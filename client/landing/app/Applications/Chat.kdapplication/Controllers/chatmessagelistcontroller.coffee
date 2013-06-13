class ChatMessageListController extends CommonChatController

  addItem:(event, message)->
    sender   = (event.split '.').last

    lastItem = @itemsOrdered.last
    if lastItem and lastItem.data?.sender is sender
      lastItem.addMessage message
    else
      cssClass = if sender is KD.nick() then 'mine' else ''
      super {message, sender, cssClass}

    @scrollView.scrollTo
      top      : @scrollView.getScrollHeight()
      duration : 100