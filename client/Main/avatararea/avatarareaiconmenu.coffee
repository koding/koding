class AvatarAreaIconMenu extends JView

  constructor:->

    super

    @setClass "account-menu"

    @notificationsPopup = new AvatarPopupNotifications
      cssClass : "notifications"

    @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'notifications acc-dropdown-icon'
      attributes :
        title    : 'Notifications'
      delegate   : @notificationsPopup

  pistachio:->
    """
    {{> @notificationsIcon}}
    """


  viewAppended:->

    super

    mainView = KD.getSingleton 'mainView'

    mainView.addSubView @notificationsPopup

    @attachListeners()


  attachListeners:->
    KD.getSingleton('notificationController').on 'NotificationHasArrived', ({event})=>
      # No need the following
      # @notificationsIcon.updateCount @notificationsIcon.count + 1 if event is 'ActivityIsAdded'
      if event is 'ActivityIsAdded' or 'BucketIsUpdated'
        @notificationsPopup.listController.fetchNotificationTeasers (notifications)=>
          @notificationsPopup.noNotification.hide()
          @notificationsPopup.listController.removeAllItems()
          @notificationsPopup.listController.instantiateListItems notifications

    @notificationsPopup.listController.on 'NotificationCountDidChange', (count)=>
      @utils.killWait @notificationsPopup.loaderTimeout
      if count > 0
      then @notificationsPopup.noNotification.hide()
      else @notificationsPopup.noNotification.show()
      @notificationsIcon.updateCount count

  accountChanged:(account)->

    {notificationsPopup} = this

    notificationsPopup.listController.removeAllItems()

    if KD.isLoggedIn()

      # Fetch Notifications
      notificationsPopup.listController.fetchNotificationTeasers (teasers)=>
        notificationsPopup.listController.instantiateListItems teasers
