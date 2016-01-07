kd                          = require 'kd'
isLoggedIn                  = require '../util/isLoggedIn'
AvatarPopup                 = require '../avatararea/avatarpopup'
NotificationListController  = require './notificationlistcontroller'
NotificationListItemView    = require './notificationlistitemview'
PopupList                   = require '../avatararea/popuplist'
isKoding                    = require 'app/util/isKoding'



module.exports = class PopupNotifications extends AvatarPopup

  constructor: (options = {}, data) ->

    options.cssClass = kd.utils.curry 'popup-notifications', options.cssClass

    super options, data

    @notLoggedInMessage = 'Login required to see notifications'


  viewAppended: ->

    super

    @_popupList = new PopupList
      itemClass : NotificationListItemView
      delegate  : this

    @listController = new NotificationListController
      view         : @_popupList
      maxItems     : 5

    @listController.on 'AvatarPopupShouldBeHidden', @bound 'hide'

    @forwardEvent @listController, 'NotificationCountDidChange'
    @forwardEvent @listController, 'AvatarPopupShouldBeHidden'

    @avatarPopupContent.addSubView @listController.getView()
    @addAccountMenu()  unless isKoding()

    @updateItems()

    @attachListeners()

    { mainController } = kd.singletons
    mainController.on 'AccountChanged', @bound 'attachListeners'


  addAccountMenu: ->

    @avatarPopupContent.addSubView ul = new kd.CustomHTMLView
      tagName  : 'ul'
      cssClass : 'popup-settings'
      click    : (event) => if event.target.tagName is 'A' then @hide()
      partial  : """
        <li class='account'><a href='/Account'>Account</a></li>
        <li class='admin hidden'><a href='/Admin'>Team Settings</a></li>
        <li class='support'><a href='http://learn.koding.com'>Support</a></li>
        <li class='logout'><a href='/Logout'>Logout</a></li>
        """

    { groupsController } = kd.singletons
    groupsController.ready ->
      group = groupsController.getCurrentGroup()
      group.canEditGroup (err, success) ->
        unless success
        then ul.$('li.admin').remove()
        else ul.$('li.admin').removeClass('hidden')


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
