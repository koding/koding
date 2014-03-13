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
      troubleshoot = KD.singleton("troubleshoot")
      @_modal = new TroubleshootModal {}, troubleshoot.getItems()

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

    @init()

  init: ->
    @bongo = new TroubleshootItemView
      title: "Bongo"
    , @getData()["bongo"]

    @broker = new TroubleshootItemView
      title : "Broker"
    , @getData()["broker"]

    @kiteBroker = new TroubleshootItemView
      title : "Kite-Broker"
    , @getData()["kiteBroker"]

    @osKite = new TroubleshootItemView
      title : "OS-Kite"
    , @getData()["osKite"]

    @webServer = new TroubleshootItemView
      title : "Webserver"
    , @getData()["webServer"]

    @connection = new TroubleshootItemView
      title : "Internet Connection"
    , @getData()["connection"]


    @addSubView @bongo
    @addSubView @broker
    @addSubView @kiteBroker
    @addSubView @osKite
    @addSubView @webServer
    @addSubView @connection
class TroubleshootItemView extends KDCustomHTMLView

  constructor: (options, data) ->

    super options, data

    @loader = new KDLoaderView
      size          : width : 16
      showLoader    : yes

    @getData().on "healthCheckCompleted", =>
      @loader.hide()
      @render()

    # @addSubView @loader
      # console.log 'data', @getData()

  viewAppended: ->
    JView::viewAppended.call this

  getResponseTime: ->
    responseTime = @getData().getResponseTime()
    return "#{responseTime} ms" unless responseTime is ""

    responseTime


  pistachio:->
    {title} = @getOptions()
    """
      {{> @loader}}  #{title} : {{ #(status) }} {{@getResponseTime #(dummy) }}
    """

