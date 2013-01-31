# avatar popup box Notifications
class AvatarPopupNotifications extends AvatarPopup
  activitesArrived:-> log arguments

  viewAppended:->
    super()

    @_popupList = new PopupList
      itemClass : PopupNotificationListItem
      # lastToFirst   : yes

    @listController = new MessagesListController
      view         : @_popupList
      maxItems     : 5

    @listController.registerListener
      KDEventTypes  : "AvatarPopupShouldBeHidden"
      listener      : @
      callback      : => @hide()

    @avatarPopupContent.addSubView @noNotification = new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "You have no new notifications..."
    @noNotification.hide()

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView redirectLink = new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>View all of your activity notifications...</a>"

    @listenTo
      KDEventTypes        : "click"
      listenedToInstance  : redirectLink
      callback            : ()=>
        appManager.openApplication('Inbox')
        appManager.tell 'Inbox', "goToNotifications"
        @hide()

  show:->
    super

  hide:->
    KD.whoami()?.glanceActivities =>
      for item in @listController.itemsOrdered
        item.unsetClass 'unread'
      @noNotification.show()
      @listController.emit 'NotificationCountDidChange', 0
    super
