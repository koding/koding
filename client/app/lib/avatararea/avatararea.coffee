kd                 = require 'kd'
KDCustomHTMLView   = kd.CustomHTMLView
AvatarAreaIconLink = require './avatarareaiconlink'
AccountPopup       = require './accountpopup'
AvatarView         = require '../commonviews/avatarviews/avatarview'
AvatarStaticView   = require '../commonviews/avatarviews/avatarstaticview'
JView              = require '../jview'
PopupNotifications = require '../notifications/popupnotifications'
JCustomHTMLView    = require 'app/jcustomhtmlview'
isKoding           = require 'app/util/isKoding'


module.exports = class AvatarArea extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data)->

    options.cssClass or= 'avatar-area'

    super options, data

    { mainView } = kd.singletons
    account      = @getData()
    {profile} = @getData()

    if isKoding()
      @avatar = new AvatarView
        cssClass   : 'avatar-image-wrapper'
        attributes :
          title    : 'View your public profile'
        size       :
          width    : 25
          height   : 25
      , account
    else
      @avatar = new AvatarStaticView
        cssClass   : 'avatar-image-wrapper'
        attributes :
          title    : 'View your notifications and account settings'
        size       :
          width    : 25
          height   : 25
        click      : =>
          @notificationsIcon.click()
      , account

    @profileName = new JCustomHTMLView
      tagName    : 'a'
      cssClass   : 'profile'
      attributes :
        href     : "/#{profile.nickname}"
        title    : 'Your profile'
      pistachio  : '{{ #(profile.firstName) }}'
    , account

    @accountPopup = new AccountPopup

    @accountIcon = new AvatarAreaIconLink
      cssClass   : 'acc-dropdown-icon'
      attributes :
        title    : 'Account'
        testpath : 'AvatarAreaIconLink'
      delegate   : @accountPopup

    @notificationsPopup = new PopupNotifications
      cssClass : if isKoding() then 'notification-list' else 'notification-list team'

    @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'notifications acc-notification-icon'
      attributes :
        title    : 'Notifications'
      delegate   : @notificationsPopup


    @on 'viewAppended', ->

      mainView.addSubView @accountPopup
      mainView.addSubView @notificationsPopup

      @notificationsPopup.on 'NotificationCountDidChange', (count)=>
        kd.utils.killWait @notificationsPopup.loaderTimeout
        @notificationsIcon.updateCount count


  pistachio: ->

    if isKoding()
      """
      {{> @avatar}}
      {{> @profileName}}
      {{> @accountIcon}}
      {{> @notificationsIcon}}
      """
    else
      """
      {{> @accountIcon}}
      {{> @avatar}}
      {{> @notificationsIcon}}
      """
