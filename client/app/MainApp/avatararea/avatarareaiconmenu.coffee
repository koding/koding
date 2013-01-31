class AvatarAreaIconMenu extends KDView
  constructor:->
    super
    @setClass "actions"

  viewAppended:->
    mainView = @getSingleton 'mainView'
    sidebar  = @getDelegate()
    @setClass "invisible" unless KD.isLoggedIn()

    mainView.addSubView @avatarNotificationsPopup = new AvatarPopupNotifications
      cssClass : "notifications"
      delegate : sidebar

    mainView.addSubView @avatarMessagesPopup = new AvatarPopupMessages
      cssClass : "messages"
      delegate : sidebar

    mainView.addSubView @avatarStatusUpdatePopup = new AvatarPopupShareStatus
      cssClass : "status-update"
      delegate : sidebar

    @addSubView @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'notifications'
      attributes :
        title    : 'Notifications'
      delegate   : @avatarNotificationsPopup

    @addSubView @messagesIcon = new AvatarAreaIconLink
      cssClass   : 'messages'
      attributes :
        title    : 'Messages'
      delegate   : @avatarMessagesPopup

    @addSubView @statusUpdateIcon = new AvatarAreaIconLink
      cssClass   : 'status-update'
      attributes :
        title    : 'Status Update'
      delegate   : @avatarStatusUpdatePopup

    @attachListeners()

  attachListeners:->

    @getSingleton('notificationController').on 'NotificationHasArrived', ({event})=>
      # No need the following
      # @notificationsIcon.updateCount @notificationsIcon.count + 1 if event is 'ActivityIsAdded'
      if event is 'ActivityIsAdded'
        @avatarNotificationsPopup.listController.fetchNotificationTeasers (notifications)=>
          @avatarNotificationsPopup.noNotification.hide()
          @avatarNotificationsPopup.listController.removeAllItems()
          @avatarNotificationsPopup.listController.instantiateListItems notifications

    @avatarNotificationsPopup.listController.on 'NotificationCountDidChange', (count)=>
      @utils.killWait @avatarNotificationsPopup.loaderTimeout
      if count > 0
        @avatarNotificationsPopup.noNotification.hide()
      else
        @avatarNotificationsPopup.noNotification.show()
      @notificationsIcon.updateCount count

    @avatarMessagesPopup.listController.on 'MessageCountDidChange', (count)=>
      @utils.killWait @avatarMessagesPopup.loaderTimeout
      if count > 0
        @avatarMessagesPopup.noMessage.hide()
      else
        @avatarMessagesPopup.noMessage.show()
      @messagesIcon.updateCount count

  accountChanged:(account)->
    if KD.isLoggedIn()
      @unsetClass "invisible"
      notificationsPopup = @avatarNotificationsPopup
      messagesPopup      = @avatarMessagesPopup
      messagesPopup.listController.removeAllItems()
      notificationsPopup.listController.removeAllItems()

      # do not remove the timeout it should give dom sometime before putting an extra load
      notificationsPopup.loaderTimeout = @utils.wait 5000, =>
        notificationsPopup.listController.fetchNotificationTeasers (teasers)=>
          notificationsPopup.listController.instantiateListItems teasers

      messagesPopup.loaderTimeout = @utils.wait 5000, =>
        messagesPopup.listController.fetchMessages()

    else
      @setClass "invisible"

    @avatarMessagesPopup.accountChanged()
