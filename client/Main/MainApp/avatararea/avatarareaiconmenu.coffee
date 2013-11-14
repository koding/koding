class AvatarAreaIconMenu extends JView

  constructor:->

    super

    @setClass "account-menu"

    @notificationsPopup = new AvatarPopupNotifications
      cssClass : "notifications"

    @messagesPopup = new AvatarPopupMessages
      cssClass : "messages"

    @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'notifications acc-dropdown-icon'
      attributes :
        title    : 'Notifications'
      delegate   : @notificationsPopup

    @messagesIcon = new AvatarAreaIconLink
      cssClass   : 'messages acc-dropdown-icon'
      testPath   : "avatararea-messages-icon"
      attributes :
        title    : 'Messages'
      delegate   : @messagesPopup

    @accountIcon = new KDCustomHTMLView
      tagName    : "a"
      cssClass   : 'account acc-dropdown-icon'
      attributes :
        title    : 'Account Settings'
        href     : "#"
      click      : (event)->
        KD.utils.stopDOMEvent event
        KD.getSingleton('router').handleRoute '/Account'
      partial    : "<span class='count'><cite></cite></span><span class='icon'></span>"


  pistachio:->
    """
    {{> @accountIcon}}
    {{> @messagesIcon}}
    {{> @notificationsIcon}}
    """


  viewAppended:->

    super

    mainView = KD.getSingleton 'mainView'

    mainView.addSubView @notificationsPopup
    mainView.addSubView @messagesPopup

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

    @messagesPopup.listController.on 'MessageCountDidChange', (count)=>
      if count > 0
      then @messagesPopup.noMessage.hide()
      else @messagesPopup.noMessage.show()
      @messagesIcon.updateCount count


  accountChanged:(account)->

    {notificationsPopup, messagesPopup} = this

    messagesPopup.listController.removeAllItems()
    notificationsPopup.listController.removeAllItems()

    if KD.isLoggedIn()

      # Fetch Notifications
      notificationsPopup.listController.fetchNotificationTeasers (teasers)=>
        notificationsPopup.listController.instantiateListItems teasers

      # Fetch Private Messages
      messagesPopup.listController.fetchMessages()
