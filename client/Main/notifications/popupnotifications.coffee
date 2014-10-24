class PopupNotifications extends AvatarPopup

  constructor: (options = {}, data) ->

    options.cssClass = KD.utils.curry 'popup-notifications', options.cssClass

    super options, data

    @notLoggedInMessage = 'Login required to see notifications'


  viewAppended: ->
    super

    @_popupList = new PopupList
      itemClass : NotificationListItemView

    @listController = new NotificationListController
      view         : @_popupList
      maxItems     : 5

    @listController.on "AvatarPopupShouldBeHidden", @bound 'hide'

    @forwardEvent @listController, 'NotificationCountDidChange'
    @forwardEvent @listController, 'AvatarPopupShouldBeHidden'

    @avatarPopupContent.addSubView @listController.getView()

    @updateItems()

    @attachListeners()

    KD.getSingleton('mainController').on "AccountChanged", =>
      @attachListeners()

  hide: ->

    super

    if KD.isLoggedIn()
      {notifications} = KD.singletons.socialapi
      notifications.glance {}, (err) =>
        return warn err.error, err.description  if err

        @listController.emit 'NotificationCountDidChange', 0


  accountChanged:(account)->
    super

    @updateItems()

  updateItems: ->
    return unless @listController

    @listController.removeAllItems()

    if KD.isLoggedIn()
      # Fetch Notifications
      @listController.fetchNotificationTeasers (err, notifications)=>
        return warn "Notifications cannot be received", err  if err
        @listController.instantiateListItems notifications

  attachListeners: ->
    {notificationController} = KD.singletons
    notificationController.off 'NotificationHasArrived'
    notificationController.on 'NotificationHasArrived', ({event})=>
    #   # No need the following
    #   # @notificationsIcon.updateCount @notificationsIcon.count + 1 if event is 'ActivityIsAdded'
      if event is 'NotificationAdded'
        @listController.fetchNotificationTeasers (err, notifications)=>
          return warn "Notifications cannot be received", err  if err
          @listController.removeAllItems()
          @listController.instantiateListItems notifications

