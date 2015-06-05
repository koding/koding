kd                          = require 'kd'
isLoggedIn                  = require '../util/isLoggedIn'
AvatarPopup                 = require '../avatararea/avatarpopup'
NotificationListController  = require './notificationlistcontroller'
NotificationListItemView    = require './notificationlistitemview'
PopupList                   = require '../avatararea/popuplist'


module.exports = class PopupNotifications extends AvatarPopup

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'popup-notifications', options.cssClass

    super options, data

    @notLoggedInMessage = 'Login required to see notifications'


  viewAppended: ->
    super

    @_popupList = new PopupList
      itemClass : NotificationListItemView
      delegate  : @

    @listController = new NotificationListController
      view         : @_popupList
      maxItems     : 5

    @listController.on 'AvatarPopupShouldBeHidden', @bound 'hide'

    @forwardEvent @listController, 'NotificationCountDidChange'
    @forwardEvent @listController, 'AvatarPopupShouldBeHidden'

    @avatarPopupContent.addSubView @listController.getView()

    @updateItems()

    @attachListeners()

    kd.getSingleton('mainController').on "AccountChanged", =>
      @attachListeners()

  hide: ->

    super

    if isLoggedIn()
      {notifications} = kd.singletons.socialapi
      notifications.glance {}, (err) =>
        return kd.warn err.error, err.description  if err

        @listController.emit 'NotificationCountDidChange', 0


  accountChanged:(account)->
    super

    @updateItems()

  updateItems: ->
    return unless @listController

    @listController.removeAllItems()

    if isLoggedIn()
      # Fetch Notifications
      @listController.fetchNotificationTeasers (err, notifications)=>
        return kd.warn "Notifications cannot be received", err  if err
        @listController.instantiateListItems notifications

  attachListeners: ->
    {notificationController} = kd.singletons
    notificationController.off 'NotificationHasArrived'
    notificationController.on 'NotificationHasArrived', ({event})=>
    #   # No need the following
    #   # @notificationsIcon.updateCount @notificationsIcon.count + 1 if event is 'ActivityIsAdded'
      if event is 'NotificationAdded'
        @listController.fetchNotificationTeasers (err, notifications)=>
          return kd.warn "Notifications cannot be received", err  if err
          @listController.removeAllItems()
          @listController.instantiateListItems notifications



