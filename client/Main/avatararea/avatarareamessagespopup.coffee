class AvatarPopupMessages extends AvatarPopup

  constructor:->
    @notLoggedInMessage = 'Login required to see messages'
    super

  viewAppended:->
    super

    @_popupList = new PopupList
      itemClass  : PopupMessageListItem

    @listController = new MessagesListController
      view         : @_popupList
      maxItems     : 5

    KD.getSingleton('notificationController').on "NewMessageArrived", =>
      @listController.fetchMessages()

    @listController.on "AvatarPopupShouldBeHidden", @bound 'hide'

    @avatarPopupContent.addSubView @noMessage = new KDView
      height   : "auto"
      cssClass : "sublink top hidden"
      partial  : "You have no new messages."

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all messages...</a>"
      click    : =>
        appManager = KD.getSingleton "appManager"
        appManager.open('Inbox')
        appManager.tell 'Inbox', "goToMessages"
        @hide()

  show:->
    super
    @listController.fetchMessages()