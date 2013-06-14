class StaticAvatarAreaIconMenu extends JView

  constructor:->

    super

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

    mainView = KD.getSingleton 'mainView'

    mainView.addSubView @notificationsPopup
    mainView.addSubView @messageUserPopup
    mainView.addSubView @quickNavPopup

    @attachListeners @getData()


  attachListeners:(profileUser)->

    @on 'CustomizeLinkClicked', =>
      @messageUserPopup.emit 'CustomizeLinkClicked'


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



    # @avatarPopupContent.addSubView inputWrapper = new KDView
    #   cssClass : 'static-profile-send-message-input-wrapper'

    @avatarPopupContent.addSubView sendMessageLink = new MemberMailLink
      cssClass : 'sublink profile-message-link'
    , data

    # @avatarPopupContent.addSubView new KDView
    #   height   : "auto"
    #   cssClass : "sublink"
    #   partial  : "Send this user a message:"
    #   click    : =>
    #     @hide()

    # inputWrapper.addSubView new KDHitEnterInputView
    #   type : 'textarea'
    #   cssClass : 'static-profile-send-message-input'
    #   autoGrow: yes
    #   callback :(value)=>
    #     new KDNotificationView
    #       title : 'Sending messages to this user is currently disabled.'
    #     @hide()

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
    super
    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See all activities of this user...</a>"
      click    : =>
        new KDNotificationView
          title : 'Coming soon'
        @hide()
  show:->
    super

class AvatarPopupStaticProfileQuickNav extends AvatarPopup

  viewAppended:->
    super()

    @avatarPopupContent.addSubView new KDView
      height   : "auto"
      cssClass : "sublink"
      partial  : "<a href='#'>See this users Groups...</a>"
      click    : =>
        new KDNotificationView
          title : 'Coming soon'
        @hide()

  show:->
    super
