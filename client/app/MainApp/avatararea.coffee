class AvatarArea extends KDView
  constructor:(options,{account})->
    super options,account
    {@profile} = account

    @avatar       = new AvatarView {
      tagName  : "div"
      cssClass : "avatar-image-wrapper"
      size     : { width: 160, height: 76 }
    },account
  
  pistachio:-> "{{> @avatar}}"
  
  viewAppended:->
    @setTemplate @pistachio()
    @template.update()

class AvatarAreaIconLink extends KDCustomHTMLView
  constructor:(options,data)->
    options = $.extend
      tagName     : "a"
      partial     : "<span class='count'><cite></cite><span class='arrow-wrap'><span class='arrow'></span></span></span><span class='icon'></span>"
      attributes  :
        href      : "#"
    ,options
    super options,data
  
  updateCount:(newCount = 0)->
    @$('.count cite').text newCount

    if newCount is 0
      @$('.count').removeClass "in"
    else
      @$('.count').addClass "in"
  
  click:->
    popup = @getDelegate()
    popup.show()
  

class AvatarAreaIconMenu extends KDView
  constructor:->
    super
    @setClass "actions"
  
  viewAppended:->
    mainView = @getSingleton 'mainView'
    sidebar  = @getDelegate()
    @setClass "invisible" unless @getSingleton('mainController').isUserLoggedIn()
  
    mainView.addSubView @avatarStatusUpdatePopup = new AvatarPopupShareStatus
      cssClass : "status-update"
      delegate : sidebar

    mainView.addSubView @avatarNotificationsPopup = new AvatarPopupNotifications
      cssClass : "notifications"
      delegate : sidebar

    mainView.addSubView @avatarMessagesPopup = new AvatarPopupMessages
      cssClass : "messages"
      delegate : sidebar
  
    @addSubView @statusUpdateIcon = new AvatarAreaIconLink 
      cssClass   : 'status-update'
      attributes :
        title    : 'Status Update'
      delegate   : @avatarStatusUpdatePopup

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
  
    @attachListeners()
  
  attachListeners:->
    @avatarNotificationsPopup.listController.registerListener
      KDEventTypes  : 'NotificationCountDidChange'
      listener      : @ 
      callback      : (publishingInstance, event)=>
        {count} = event
        clearTimeout @avatarNotificationsPopup.loaderTimeout
        @notificationsIcon.updateCount count

    @avatarMessagesPopup.listController.registerListener
      KDEventTypes  : 'MessageCountDidChange'
      listener      : @
      callback      : (publishingInstance, event)=>
        {count} = event
        clearTimeout @avatarMessagesPopup.loaderTimeout
        @messagesIcon.updateCount count
  
  accountChanged:(account)->
    if @getSingleton('mainController').isUserLoggedIn()
      @unsetClass "invisible"
      #do not remove the timeout it should give dom sometime before putting an extra load
      @avatarNotificationsPopup.loaderTimeout = setTimeout =>
        @avatarNotificationsPopup.listController.fetchNotificationTeasers()
      ,3000

      @avatarMessagesPopup.loaderTimeout = setTimeout =>
        @avatarMessagesPopup.listController.fetchMessages()
      ,3000
    else
      @setClass "invisible"

    @avatarMessagesPopup.accountChanged()

class AvatarPopup extends KDView
  constructor:->
    super
    @sidebar = @getDelegate()

    @listenTo 
      KDEventTypes       : "NavigationPanelWillCollapse"
      listenedToInstance : @sidebar
      callback           : @hide

    @listenTo
      KDEventTypes       : "ReceivedClickElsewhere"
      listenedToInstance : @
      callback           : @hide

    @_windowController = @getSingleton('windowController')
    @listenWindowResize()

  show:->
    @_windowDidResize()
    @_windowController.addLayer @
    @sidebar.propagateEvent KDEventType : "AvatarPopupIsActive"
    @setClass "active"
    @

  hide:->
    @_windowController.removeLayer @
    @sidebar.propagateEvent KDEventType : "AvatarPopupIsInactive"
    @unsetClass "active"
    @

  viewAppended:->
    @setClass "avatararea-popup"
    @addSubView @avatarPopupTab = new KDView cssClass : 'tab', partial : '<span class="avatararea-popup-close"></span>'
    @setPopupListener()
    @addSubView @avatarPopupContent = new KDView cssClass : 'content'

  setPopupListener:->
    @listenTo
      KDEventTypes        : 'click'
      listenedToInstance  : @avatarPopupTab
      callback        :(pubInst, event)->
        @hide()
  
  _windowDidResize:=>
    if @listController
      {scrollView}    = @listController
      windowHeight    = $(window).height()
      avatarTopOffset = @$().offset().top
      @listController.scrollView.$().css maxHeight : windowHeight - avatarTopOffset - 50
    


# avatar popup box Status Update Form
class AvatarPopupShareStatus extends AvatarPopup
  show:->
    super()
    
    if (visitor = KD.getSingleton('mainController').getVisitor())
      {profile} = visitor.currentDelegate
      if @statusField.getOptions().placeholder is ""
        @statusField.inputSetPlaceHolder "What's new, #{profile.firstName}?"
    
  viewAppended:->
    super()

    @avatarPopupContent.addSubView @statusField = new KDHitEnterInputView
      type          : "textarea"
      validate      :
        rules       :
          required  : yes
      callback      : @updateStatus


  updateStatus:(status)=> 
    bongo.api.JStatusUpdate.create body : status, (err,reply)=>
      unless err
        appManager.tell 'Activity', 'ownActivityArrived', reply
        new KDNotificationView
          type     : 'growl'
          title    : 'Your status updated!'
          content  : reply.body
          duration : 5000
          timer    : yes
          overlay  : yes
        @statusField.inputSetValue ""
        @statusField.inputSetPlaceHolder reply.body
        @hide()
        
      else
        new KDNotificationView title : "There was an error, try again later!"
        @hide()
        
# avatar popup box Notifications
class AvatarPopupNotifications extends AvatarPopup
  viewAppended:->
    super()

    @_popupList = new PopupList 
      subItemClass : PopupNotificationListItem

    @listController = new MessagesListController 
      view         : @_popupList
      maxItems     : 5

    @listController.registerListener
      KDEventTypes  : "AvatarPopupShouldBeHidden"
      listener      : @
      callback      : => @hide()
    
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

class AvatarPopupMessages extends AvatarPopup
  
  viewAppended:->
    super()
    
    @_popupList = new PopupList
      subItemClass  : PopupMessageListItem
      lastToFirst   : yes
    
    @listController = new MessagesListController 
      view         : @_popupList
      maxItems     : 5

    @listController.registerListener
      KDEventTypes  : "AvatarPopupShouldBeHidden"
      listener      : @
      callback      : => @hide()

    @listController.registerListener
      KDEventTypes  : "AvatarPopupShouldBeHidden"
      listener      : @
      callback      : => @hide()
    
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
  constructor:(options,data)->
    options = $.extend
      tagName   : "ul"
      cssClass  : "avatararea-popup-list"
    ,options
    super options,data
  
class PopupNotificationListItem extends NotificationListItem
  constructor:(options,data)->
    options = $.extend
      tagName        : "li"
      linkGroupClass : ProfileTextGroup
      avatarClass    : AvatarStaticView
    ,options

    super options,data

  pistachio:->
    """
      <span class='avatar'>{{> @avatar}}</span>
      <div class='right-overflow'>
        <p>{{> @participants}} {{@getActionPhrase #(0.as)}} {{@getActivityPlot #(0.sourceName)}}</p>
        <footer>
          <time>{{$.timeago @getLatestTimeStamp #(0.timestamp)}}</time>
        </footer>
      </div>
    """
  click:(event)->
    appManager.openApplication 'Inbox'
    appManager.tell "Inbox", "goToNotifications", @
    popupList = @getDelegate()
    popupList.propagateEvent KDEventType : 'AvatarPopupShouldBeHidden'


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
    @avatar       = new AvatarStaticView {
      size    : {width: 40, height: 40}
      origin  : group[0]
    }
  
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
        <time>{{> @participants}} {{$.timeago #(meta.createdAt)}}</time>
      </footer>
    </div>
    """
