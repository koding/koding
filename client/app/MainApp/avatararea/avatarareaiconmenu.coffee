class AvatarAreaIconMenu extends JView

  constructor:->

    super

    @setClass "actions"
    @setClass "invisible" unless KD.isLoggedIn()

    sidebar  = @getDelegate()

    @notificationsPopup = new AvatarPopupNotifications
      cssClass : "notifications"
      delegate : sidebar

    @messagesPopup = new AvatarPopupMessages
      cssClass : "messages"
      delegate : sidebar

    @groupSwitcherPopup = new AvatarPopupGroupSwitcher
      cssClass : "group-switcher"
      delegate : sidebar

    @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'notifications'
      attributes :
        title    : 'Notifications'
      delegate   : @notificationsPopup

    @messagesIcon = new AvatarAreaIconLink
      cssClass   : 'messages'
      attributes :
        title    : 'Messages'
      delegate   : @messagesPopup

    @groupsSwitcherIcon = new AvatarAreaIconLink
      cssClass   : 'group-switcher'
      attributes :
        title    : 'Your groups'
      delegate   : @groupSwitcherPopup

  pistachio:->
    """
      {{> @notificationsIcon}}
      {{> @messagesIcon}}
      {{> @groupsSwitcherIcon}}
    """

  viewAppended:->

    super

    mainView = @getSingleton 'mainView'

    mainView.addSubView @notificationsPopup
    mainView.addSubView @messagesPopup
    mainView.addSubView @groupSwitcherPopup

    @attachListeners()


  attachListeners:->

    @getSingleton('notificationController').on 'NotificationHasArrived', ({event})=>
      # No need the following
      # @notificationsIcon.updateCount @notificationsIcon.count + 1 if event is 'ActivityIsAdded'
      if event is 'ActivityIsAdded'
        @notificationsPopup.listController.fetchNotificationTeasers (notifications)=>
          @notificationsPopup.noNotification.hide()
          @notificationsPopup.listController.removeAllItems()
          @notificationsPopup.listController.instantiateListItems notifications

    @notificationsPopup.listController.on 'NotificationCountDidChange', (count)=>
      @utils.killWait @notificationsPopup.loaderTimeout
      if count > 0
        @notificationsPopup.noNotification.hide()
      else
        @notificationsPopup.noNotification.show()
      @notificationsIcon.updateCount count

    @messagesPopup.listController.on 'MessageCountDidChange', (count)=>
      @utils.killWait @messagesPopup.loaderTimeout
      if count > 0
        @messagesPopup.noMessage.hide()
      else
        @messagesPopup.noMessage.show()
      @messagesIcon.updateCount count

  accountChanged:(account)->
    if KD.isLoggedIn()
      @unsetClass "invisible"
      notificationsPopup = @notificationsPopup
      messagesPopup      = @messagesPopup
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

    @messagesPopup.accountChanged()
