class AvatarAreaIconLink extends KDCustomHTMLView
  constructor:(options,data)->
    options = $.extend
      tagName     : "a"
      partial     : "<span class='count'><cite></cite><span class='arrow-wrap'><span class='arrow'></span></span></span><span class='icon'></span>"
      attributes  :
        href      : "#"
    ,options
    super options,data
    @count = 0

  updateCount:(newCount = 0)->
    @$('.count cite').text newCount
    @count = newCount

    if newCount is 0
      @$('.count').removeClass "in"
    else
      @$('.count').addClass "in"

  click:(event)->
    event.preventDefault()
    event.stopPropagation()
    popup = @getDelegate()
    popup.show()


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

class AvatarPopup extends KDView
  constructor:->
    super
    @sidebar = @getDelegate()

    @sidebar.on "NavigationPanelWillCollapse", => @hide()

    @on 'ReceivedClickElsewhere', => @hide()

    @_windowController = @getSingleton('windowController')
    @listenWindowResize()

  show:->
    @utils.killWait @loaderTimeout
    @_windowDidResize()
    @_windowController.addLayer @
    @getSingleton('mainController').emit "AvatarPopupIsActive"
    @setClass "active"
    @

  hide:->
    @getSingleton('mainController').emit "AvatarPopupIsInactive"
    @unsetClass "active"
    @

  viewAppended:->
    @setClass "avatararea-popup"
    @addSubView @avatarPopupTab = new KDView cssClass : 'tab', partial : '<span class="avatararea-popup-close"></span>'
    @setPopupListener()
    @addSubView @avatarPopupContent = new KDView cssClass : 'content'

  setPopupListener:->
    @avatarPopupTab.on 'click', (event)=>
      @hide()

  _windowDidResize:=>
    if @listController
      {scrollView}    = @listController
      windowHeight    = $(window).height()
      avatarTopOffset = @$().offset().top
      @listController.scrollView.$().css maxHeight : windowHeight - avatarTopOffset - 50

# avatar popup box Status Update Form
class AvatarPopupShareStatus extends AvatarPopup

  viewAppended:->
    super()

    @loader = new KDLoaderView
      cssClass      : "avatar-popup-status-loader"
      size          :
        width       : 30
      loaderOptions :
        color       : "#ff9200"
        shape       : "spiral"
        diameter    : 30
        density     : 30
        range       : 0.4
        speed       : 1
        FPS         : 24

    @avatarPopupContent.addSubView @loader

    {profile} = KD.whoami()

    @avatarPopupContent.addSubView @statusField = new KDHitEnterInputView
      type          : "textarea"
      validate      :
        rules       :
          required  : yes
      placeholder   : "What's new, #{Encoder.htmlDecode profile.firstName}?"
      callback      : (status)=> @updateStatus status

  updateStatus:(status)->

    @loader.show()
    KD.remote.api.JStatusUpdate.create body : status, (err,reply)=>
      unless err
        appManager.tell 'Activity', 'ownActivityArrived', reply
        new KDNotificationView
          type     : 'growl'
          cssClass : 'mini'
          title    : 'Message posted!'
          duration : 2000
        @statusField.setValue ""

        @loader.hide()
        # @statusField.setPlaceHolder reply.body
        @hide()

      else
        new KDNotificationView type : "mini", title : "There was an error, try again later!"
        @loader.hide()
        @hide()

# avatar popup box Notifications
class AvatarPopupNotifications extends AvatarPopup
  activitesArrived:-> log arguments

  viewAppended:->
    super()

    @_popupList = new PopupList
      itemClass : PopupNotificationListItem
      # lastToFirst   : yes

    @listController = new MessagesListController
      view         : @_popupList
      maxItems     : 5

    @listController.registerListener
      KDEventTypes  : "AvatarPopupShouldBeHidden"
      listener      : @
      callback      : => @hide()

    @avatarPopupContent.addSubView @noNotification = new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "You have no new notifications..."
    @noNotification.hide()

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView redirectLink = new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>View all of your activity notifications...</a>"

    @listenTo
      KDEventTypes        : "click"
      listenedToInstance  : redirectLink
      callback            : ()=>
        appManager.openApplication('Inbox')
        appManager.tell 'Inbox', "goToNotifications"
        @hide()

  show:->
    super

  hide:->
    KD.whoami()?.glanceActivities =>
      for item in @listController.itemsOrdered
        item.unsetClass 'unread'
      @noNotification.show()
      @listController.emit 'NotificationCountDidChange', 0
    super

class AvatarPopupMessages extends AvatarPopup

  viewAppended:->
    super()

    @_popupList = new PopupList
      itemClass  : PopupMessageListItem
      # lastToFirst   : yes

    @listController = new MessagesListController
      view         : @_popupList
      maxItems     : 5

    @getSingleton('notificationController').on "NewMessageArrived", =>
      @listController.fetchMessages()

    @listController.registerListener
      KDEventTypes  : "AvatarPopupShouldBeHidden"
      listener      : @
      callback      : => @hide()

    @avatarPopupContent.addSubView @noMessage = new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "You have no new messages..."
    @noMessage.hide()

    @avatarPopupContent.addSubView @listController.getView()

    @avatarPopupContent.addSubView redirectLink = new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all messages...</a>"

    @listenTo
      KDEventTypes        : "click"
      listenedToInstance  : redirectLink
      callback            : ->
        appManager.openApplication('Inbox')
        appManager.tell 'Inbox', "goToMessages"
        @hide()

  accountChanged:->
    @listController.removeAllItems()

  show:->
    super
    @listController.fetchMessages()

class PopupList extends KDListView

  constructor:(options = {}, data)->

    options.tagName     or= "ul"
    options.cssClass    or= "avatararea-popup-list"
    # options.lastToFirst or= no

    super options,data

class PopupNotificationListItem extends NotificationListItem

  constructor:(options = {}, data)->

    options.tagName        or= "li"
    options.linkGroupClass or= LinkGroup
    options.avatarClass    or= AvatarView

    super options, data

    @initializeReadState()

    @timeAgoView = new KDTimeAgoView {}, @getLatestTimeStamp @getData().dummy

  initializeReadState:->
    if @getData().getFlagValue('glanced')
      @unsetClass 'unread'
    else
      @setClass 'unread'

  pistachio:->
    """
      <span class='icon'></span>
      <span class='avatar'>{{> @avatar}}</span>
      <div class='right-overflow'>
        <p>{{> @participants}} {{@getActionPhrase #(dummy)}} {{@getActivityPlot #(dummy)}}</p>
        <footer>
          {{> @timeAgoView}
        </footer>
      </div>
    """

  click:(event)->

    popupList = @getDelegate()
    popupList.propagateEvent KDEventType : 'AvatarPopupShouldBeHidden'

    # If we need to use implement click to mark as read for notifications
    # Just un-comment following 3 line. A friend from past.
    # {_id} = @getData()
    # KD.whoami().glanceActivities _id, (err)=>
    #   if err then log "Error: ", err

    super

class PopupMessageListItem extends KDListItemView
  constructor:(options,data)->
    options = $.extend
      tagName : "li"
    ,options

    super options,data

    @initializeReadState()

    group = data.participants.map (participant)->
      constructorName : participant.sourceName
      id              : participant.sourceId

    @participants = new ProfileTextGroup {group}
    @participants.hide() if group.length is 0

    @avatar       = new AvatarStaticView {
      size    : {width: 40, height: 40}
      origin  : group[0]
    }

    @timeAgoView = new KDTimeAgoView {}, @getData().meta.createdAt

  initializeReadState:->
    if @getData().getFlagValue('read')
      @unsetClass 'unread'
    else
      @setClass 'unread'

  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

  teaser:(text)->
    __utils.shortenText(text, minLength: 40, maxLength: 70) or ''

  click:(event)->
    appManager.openApplication 'Inbox'
    appManager.tell "Inbox", "goToMessages", @
    popupList = @getDelegate()
    popupList.propagateEvent KDEventType : 'AvatarPopupShouldBeHidden'

  pistachio:->
    """
    <span class='avatar'>{{> @avatar}}</span>
    <div class='right-overflow'>
      <a href='#'>{{#(subject) or '(No title)'}}</a><br/>
      {{@teaser #(body)}}
      <footer>
        {{> @participants}} {{> @timeAgoView}}
      </footer>
    </div>
    """
