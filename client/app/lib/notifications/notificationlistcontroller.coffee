showError                 = require '../util/showError'
kd                        = require 'kd'
KDListView                = kd.ListView
KDListViewController      = kd.ListViewController
KDView                    = kd.View
NotificationListItemView  = require './notificationlistitemview'


module.exports = class NotificationListController extends KDListViewController

  constructor: (options, data) ->
    options.itemClass           or= NotificationListItemView
    options.listView            or= new KDListView
    options.startWithLazyLoader   = yes
    options.noItemFoundWidget   or= new KDView
      cssClass: 'no-item-found'
      partial : "<cite>You don't have any notifications.</cite>"

    options.lazyLoaderOptions     =
      partial                     : ''
      spinnerOptions              :
        loaderOptions             :
          color                   : '#6BB197'
        size                      :
          width                   : 32

    super options, data

    @forwardEvent @getListView(), 'AvatarPopupShouldBeHidden'

  fetchNotificationTeasers: (callback) ->
    { fetch } = kd.singletons.socialapi.notifications
    fetch {}, (err, notifications) =>
      return showError err if err?
      return showError 'Notifications could not be fetched'  unless notifications
      @emit 'NotificationCountDidChange', notifications.unreadCount
      callback null, notifications.notifications
      @hideLazyLoader()
