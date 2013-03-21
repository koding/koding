class StaticAvatarAreaIconMenu extends JView

  constructor:->

    super

    @bindEvent 'mouseenter'

    @on 'mouseenter', =>
      @getDelegate().lockSidebar = yes

    @setClass "actions"

    sidebar  = @getDelegate()

    @notificationsPopup = new AvatarPopupStaticProfileUserNotifications
      cssClass : "static-profile-popup notifications"
      delegate : sidebar
    , @getData()

    @quickNavPopup = new AvatarPopupStaticProfileQuickNav
      cssClass : "static-profile-popup group-switcher"
      delegate : sidebar
    , @getData()

    @messageUserPopup = new AvatarPopupStaticProfileUserMessage
      cssClass : 'static-profile-popup messages'
      delegate : sidebar
    , @getData()


    @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'static-profile-iconlink notifications'
      attributes :
        title    : 'Notifications'
      delegate   : @notificationsPopup

    @quickNavIcon = new AvatarAreaIconLink
      cssClass   : 'static-profile-iconlink group-switcher'
      attributes :
        title    : 'Quick Navigation'
      delegate   : @quickNavPopup

    @messageUserIcon = new AvatarAreaIconLink
      cssClass   : 'static-profile-iconlink messages'
      attributes :
        title    : 'Send a message'
      delegate   : @messageUserPopup

  pistachio:->
    """
      {{> @notificationsIcon}}
      {{> @messageUserIcon}}
      {{> @quickNavIcon}}
    """

  viewAppended:->

    super

    mainView = @getSingleton 'mainView'

    mainView.addSubView @notificationsPopup
    mainView.addSubView @messageUserPopup
    mainView.addSubView @quickNavPopup

    @attachListeners @getData()


  attachListeners:(profileUser)->

    @on 'CustomizeLinkClicked', =>
      @messageUserPopup.emit 'CustomizeLinkClicked'

    # @getSingleton('notificationController').on 'NotificationHasArrived', ({event})=>
    #   # No need the following
    #   # @notificationsIcon.updateCount @notificationsIcon.count + 1 if event is 'ActivityIsAdded'
    #   if event is 'ActivityIsAdded'
    #     @notificationsPopup.listController.fetchNotificationTeasers (notifications)=>
    #       @notificationsPopup.noNotification.hide()
    #       @notificationsPopup.listController.removeAllItems()
    #       @notificationsPopup.listController.instantiateListItems notifications

    # @notificationsPopup.listController.on 'NotificationCountDidChange', (count)=>
    #   @utils.killWait @notificationsPopup.loaderTimeout
    #   if count > 0
    #     @notificationsPopup.noNotification.hide()
    #   else
    #     @notificationsPopup.noNotification.show()
    #   @notificationsIcon.updateCount count

    # @messagesPopup.listController.on 'MessageCountDidChange', (count)=>
    #   @utils.killWait @messagesPopup.loaderTimeout
    #   if count > 0
    #     @messagesPopup.noMessage.hide()
    #   else
    #     @messagesPopup.noMessage.show()
    #   @messagesIcon.updateCount count

  accountChanged:(account)->

    # {notificationsPopup, messagesPopup, quickNavPopup} = @

    # messagesPopup.listController.removeAllItems()
    # notificationsPopup.listController.removeAllItems()
    # quickNavPopup.listController.removeAllItems()

    # if KD.isLoggedIn()
    #   @unsetClass "invisible"

    #   # log "accountChanged AvatarAreaIconMenu"

    #   # do not remove the timeout it should give dom sometime before putting an extra load
    #   notificationsPopup.loaderTimeout = @utils.wait 5000, =>
    #     notificationsPopup.listController.fetchNotificationTeasers (teasers)=>
    #       notificationsPopup.listController.instantiateListItems teasers

    #   messagesPopup.loaderTimeout = @utils.wait 5000, =>
    #     messagesPopup.listController.fetchMessages()

    #   quickNavPopup.loaderTimeout = @utils.wait 5000, =>
    #     quickNavPopup.populateGroups()

    # else
    #   @setClass "invisible"


class AvatarPopupStaticProfileUserMessage extends AvatarPopup
  HANDLE_TYPES = [
    'twitter'
    'github'
  ]
  handleMap   =
    twitter   :
      baseUrl : 'https://www.twitter.com/'
      text    : 'Twitter'
      prefix  : '@'

    github    :
      baseUrl : 'https://www.github.com/'
      text    : 'GitHub'

  viewAppended:->
    super()

    data = @getData()

    @avatarPopupContent.addSubView @linkContainer = new KDView
      cssClass : 'sublink static-link-container'

    @handleLinks  = {}

    for type in HANDLE_TYPES
      handle = data.profile.handles?[type]
      @linkContainer.addSubView @handleLinks[type]  = new StaticHandleLink
        delegate          : @
        attributes        :
          href            : "#{handleMap[type].baseUrl}#{handle or ''}"
          target          : '_blank'
        icon              :
          cssClass        : "#{type}"
        title              : handleMap[type].text
        handle             : "#{if handle then handleMap[type].prefix or '' else ''}#{if handle then handle else ''}"

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "Send this user a message:"
      click    : =>
        @hide()

    @avatarPopupContent.addSubView inputWrapper = new KDView
      cssClass : 'static-profile-send-message-input-wrapper'
    inputWrapper.addSubView new KDHitEnterInputView
      type : 'textarea'
      cssClass : 'static-profile-send-message-input'
      autoGrow: yes
      callback :(value)=>
        new KDNotificationView
          title : 'Sending messages to this user is currently disabled.'
        @hide()

    @on 'CustomizeLinkClicked', =>
      for type in HANDLE_TYPES
        @handleLinks[type].setClass 'edit'
        @handleLinks[type].addSubView new StaticHandleInput
          service     : type
          delegate    : @
          tooltip     :
            title     : "Enter your #{handleMap[type].text} handle and hit enter to save."
            placement : 'right'
            direction : 'center'
            offset    :
              left    : 5
              top     : 2
          attributes  :
            spellcheck: no
          callback    :(value)->
            data.setHandle
              service : @getOptions().service
              value   : value
        , data


  show:->
    super

class AvatarPopupStaticProfileUserNotifications extends AvatarPopup

  viewAppended:->
    super()

    selector      =
      originType  : 'JAccount'
      group       : 'koding'
    options       =
      limit       : 10

    log 'getting activities'

    KD.remote.api.CActivity.some selector, options, (err, res)=>
      log err, res

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all messages...</a>"
      click    : =>
        @hide()

  show:->
    super

class AvatarPopupStaticProfileQuickNav extends AvatarPopup

  viewAppended:->
    super()

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all messages...</a>"
      click    : =>
        @hide()

  show:->
    super