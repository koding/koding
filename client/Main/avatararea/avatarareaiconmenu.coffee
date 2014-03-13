class AvatarAreaIconMenu extends JView

  constructor:->

    super

    @setClass "account-menu"

    @troubleshootIcon = new AvatarAreaIconLink
      cssClass   : "help acc-dropdown-icon"
      attributes :
        title    : "Troubleshoot"

    @helpIcon    = new AvatarAreaIconLink
      cssClass   : "help acc-dropdown-icon"
      attributes :
        title    : 'Help'

    @helpIcon.click = (event)=>
      KD.singletons.helpController.showHelp this
      KD.utils.stopDOMEvent event
      @animation?.destroy()

    @troubleshootIcon.click = (event) =>
      @_modal?.destroy()
      @_modal = new TroubleshootModal

    @notificationsPopup = new AvatarPopupNotifications
      cssClass : "notifications"

    @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'notifications acc-dropdown-icon'
      attributes :
        title    : 'Notifications'
      delegate   : @notificationsPopup

    {mainController} = KD.singletons
    mainController.ready =>
      storage = KD.singletons.localStorageController.storage('HelpController')
      unless storage.getValue 'shown'
        # KD.utils.wait 5000, =>
        #   KD.singletons.helpController.showHelp @helpIcon
        @helpIcon.addSubView @animation = new KDCustomHTMLView
          tagName    : "span"
          cssClass   : "intro-marker in help"

  pistachio:->
    """
    {{> @troubleshootIcon}}
    {{> @helpIcon}}
    {{> @notificationsIcon}}
    """

  viewAppended:->

    super

    mainView = KD.getSingleton 'mainView'
    mainView.addSubView @notificationsPopup

    @attachListeners()
    KD.getSingleton('mainController').on "AccountChanged", =>
      @attachListeners()


  attachListeners:->
    KD.getSingleton('notificationController').on 'NotificationHasArrived', ({event})=>
      # No need the following
      # @notificationsIcon.updateCount @notificationsIcon.count + 1 if event is 'ActivityIsAdded'
      if event is 'ActivityIsAdded' or 'BucketIsUpdated'
        @notificationsPopup.listController.fetchNotificationTeasers (notifications)=>
          @notificationsPopup.noNotification.hide()
          @notificationsPopup.listController.removeAllItems()
          @notificationsPopup.listController.instantiateListItems filterNotifications notifications

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
        notificationsPopup.listController.instantiateListItems filterNotifications teasers

  filterNotifications=(notifications)->
    activityNameMap = [
      "JNewStatusUpdate"
      "JAccount"
      "JPrivateMessage"
      "JComment"
      "JReview"
      "JGroup"
    ]
    notifications.filter (notification) ->
      snapshot = JSON.parse Encoder.htmlDecode notification.snapshot
      snapshot.anchor.constructorName in activityNameMap

class TroubleshootModal extends KDModalView

  constructor: (options = {}, data) ->
    super options, data
    KD.troubleshoot()
    KD.singleton("troubleshoot").on "troubleshootCompleted", @bound "update"
    status =
      bongo :
        status : "waiting"
      broker:
        status : "waiting"
      kiteBroker:
        status : "waiting"
      osKite:
        status : "waiting"
      webServer :
        status : "waiting"
      connection :
        status : "waiting"

    @update status

  update: (response) ->
    @destroySubViews()
    @bongo = new KDCustomHTMLView
      partial : "Bongo Server Status : #{response?.bongo.status}"

    @broker = new KDCustomHTMLView
      partial : "Broker Status : #{response?.broker.status}"

    @kiteBroker = new KDCustomHTMLView
      partial : "Kite-Broker Status : #{response?.kiteBroker.status}"

    @osKite = new KDCustomHTMLView
      partial : "OS-Kite Status : #{response?.osKite.status}"

    @webServer = new KDCustomHTMLView
      partial : "Webserver Status : #{response?.webServer?.status}"

    @connection = new KDCustomHTMLView
      partial : "Internet Connection Status : #{response?.connection?.status}"

    @addSubView @bongo
    @addSubView @broker
    @addSubView @kiteBroker
    @addSubView @osKite
    @addSubView @webServer
    @addSubView @connection

