class AvatarPopupMessages extends AvatarPopup

  viewAppended:->
    super()

    @_popupList = new PopupList
      itemClass  : PopupMessageListItem
      # lastToFirst   : yes

    @listController = new MessagesListController
      view         : @_popupList
      maxItems     : 5

    @getSingleton('notificationController').on "NewMessageArrived", =>
      @listController.fetchMessages()

    @listController.registerListener
      KDEventTypes  : "AvatarPopupShouldBeHidden"
      listener      : @
      callback      : => @hide()

    @avatarPopupContent.addSubView @noMessage = new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "You have no new messages..."
    @noMessage.hide()

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView redirectLink = new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all messages...</a>"

    @listenTo
      KDEventTypes        : "click"
      listenedToInstance  : redirectLink
      callback            : ->
        appManager.openApplication('Inbox')
        appManager.tell 'Inbox', "goToMessages"
        @hide()

  accountChanged:->
    @listController.removeAllItems()

  show:->
    super
    @listController.fetchMessages()