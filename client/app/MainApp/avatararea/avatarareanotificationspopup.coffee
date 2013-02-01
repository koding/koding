class AvatarPopupNotifications extends AvatarPopup

  activitesArrived:-> #log arguments

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
      cssClass : "sublink hidden"
      partial  : "You have no new notifications..."

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>View all of your activity notifications...</a>"
      click    : =>
        appManager.openApplication('Inbox')
        appManager.tell 'Inbox', "goToNotifications"
        @hide()

  hide:->
    KD.whoami()?.glanceActivities =>
      for item in @listController.itemsOrdered
        item.unsetClass 'unread'
      @noNotification.show()
      @listController.emit 'NotificationCountDidChange', 0
    super
