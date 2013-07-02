class InboxNewMessageBar extends KDView
  viewAppended:->
    inboxMessageView = @

    @addSubView newMessageButton = new KDButtonView
      title     : "New Message"
      style     : "clean-gray new-message-button"
      callback  : => @createNewMessageModal()

    @addSubView @refreshButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "refresh"
      loader      :
        color     : "#777777"
        diameter  : 24
      tooltip     :
        title     : "Refresh"
        placement : "left"
      callback    : =>
        @emit 'RefreshButtonClicked'

    @addSubView @markMessageAsReadButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "mark-unread"
      tooltip     :
        title     : "Mark as Unread"
        placement : "left"
      callback    : =>
        @emit 'MessageShouldBeMarkedAsUnread'

    @addSubView @deleteMessageButton = new KDButtonView
      style       : "clean-gray"
      icon        : yes
      iconOnly    : yes
      iconClass   : "delete"
      tooltip     :
        title     : "Delete message"
        placement : "left"
      callback    : => @createDeleteMessageModal()

  createDeleteMessageModal:->
    modal = new KDModalView
      title          : "Delete thread"
      content        : "<div class='modalformline'>Are you sure you want to delete this thread?</div>"
      height         : "auto"
      overlay        : yes
      buttons        :
        Delete       :
          loader     :
            color    : "#ffffff"
            diameter : 16
          style      : "modal-clean-red"
          callback   : =>
            @emit 'MessageShouldBeDisowned', modal

  createNewMessageModal:->
    KD.getSingleton("appManager").tell "Inbox", "createNewMessageModal"

  disableMessageActionButtons:->
    @deleteMessageButton.getTooltip().hide()
    @deleteMessageButton.disable()
    @markMessageAsReadButton.getTooltip().hide()
    @markMessageAsReadButton.disable()

  enableMessageActionButtons:->
    @deleteMessageButton.enable()
    @markMessageAsReadButton.enable()
