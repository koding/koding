class AvatarAreaIconMenu extends JView

  constructor:->

    super

    @setClass "actions"

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

    mainView = KD.getSingleton 'mainView'

    mainView.addSubView @notificationsPopup
    mainView.addSubView @messagesPopup
    mainView.addSubView @groupSwitcherPopup

    @attachListeners()

  attachListeners:->
    KD.getSingleton('notificationController').on 'NotificationHasArrived', ({event})=>
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
      then @notificationsPopup.noNotification.hide()
      else @notificationsPopup.noNotification.show()
      @notificationsIcon.updateCount count

    @messagesPopup.listController.on 'MessageCountDidChange', (count)=>
      if count > 0
      then @messagesPopup.noMessage.hide()
      else @messagesPopup.noMessage.show()
      @messagesIcon.updateCount count

    @groupSwitcherPopup.listControllerPending.on 'PendingGroupsCountDidChange', (count)=>
      if count > 0
        @groupSwitcherPopup.invitesHeader.show()
        @groupSwitcherPopup.switchToTitle.unsetClass 'top'
      else
        @groupSwitcherPopup.invitesHeader.hide()
        @groupSwitcherPopup.switchToTitle.setClass 'top'
      @groupsSwitcherIcon.updateCount count

  accountChanged:(account)->

    {notificationsPopup, messagesPopup, groupSwitcherPopup} = @

    messagesPopup.listController.removeAllItems()
    notificationsPopup.listController.removeAllItems()
    groupSwitcherPopup.listController.removeAllItems()

    if KD.isLoggedIn()

      # Fetch Notifications
      notificationsPopup.listController.fetchNotificationTeasers (teasers)=>
        notificationsPopup.listController.instantiateListItems teasers

      # Fetch Private Messages
      messagesPopup.listController.fetchMessages()

      # Fetch Groups
      groupSwitcherPopup.populateGroups()
      groupSwitcherPopup.populatePendingGroups()

