class AvatarPopupNotifications extends AvatarPopup

  constructor:->
    @notLoggedInMessage = 'Login required to see notifications'
    super

  viewAppended:->
    super

    @_popupList = new PopupList
      itemClass : PopupNotificationListItem

    @listController = new MessagesListController
      view         : @_popupList
      maxItems     : 5

    @listController.on "AvatarPopupShouldBeHidden", @bound 'hide'

    @avatarPopupContent.addSubView @noNotification = new KDView
      height   : "auto"
      cssClass : "sublink top hidden"
      partial  : "You have no new notifications."

    @avatarPopupContent.addSubView @listController.getView()

    # @avatarPopupContent.addSubView new KDView
    #   height   : "auto"
    #   cssClass : "sublink"
    #   partial  : "<a href='#'>View all of your activity notifications...</a>"
    #   click    : =>
    #     appManager = KD.getSingleton "appManager"
    #     appManager.open('Inbox')
    #     appManager.tell 'Inbox', "goToNotifications"
    #     @hide()

  hide:->
    if KD.isLoggedIn()
      {SocialNotification} = KD.remote.api
      SocialNotification.glance (err) =>
        return warn err.error, err.description  if err

        for item in @listController.itemsOrdered
          item.unsetClass 'unread'
        @noNotification.show()
        @listController.emit 'NotificationCountDidChange', 0

    super
