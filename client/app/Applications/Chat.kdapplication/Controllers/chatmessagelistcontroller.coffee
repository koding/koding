class ChatMessageListController extends CommonChatController

  addItem:(event, message)->
    sender   = (event.split '.').last
    cssClass = if sender is KD.nick() then 'mine' else ''
    super {message, sender, cssClass}

    @scrollView.scrollTo
      top      : @scrollView.getScrollHeight()
      duration : 100