class AvatarPopupMessages extends AvatarPopup

  viewAppended:->
    super()

    @_popupList = new PopupList
      itemClass  : PopupMessageListItem

    @listController = new MessagesListController
      view         : @_popupList
      maxItems     : 5

    @getSingleton('notificationController').on "NewMessageArrived", =>
      @listController.fetchMessages()

    @listController.on "AvatarPopupShouldBeHidden", @bound 'hide'

    @avatarPopupContent.addSubView @noMessage = new KDView
      height   : "auto"
      cssClass : "sublink hidden"
      partial  : "You have no new messages..."

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all messages...</a>"
      click    : =>
        appManager.openApplication('Inbox')
        appManager.tell 'Inbox', "goToMessages"
        @hide()

  accountChanged:->
    @listController.removeAllItems()

  show:->
    super
    @listController.fetchMessages()