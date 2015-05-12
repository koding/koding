kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
AvatarAreaIconLink = require './avatarareaiconlink'
AccountPopup = require './accountpopup'
AvatarView = require '../commonviews/avatarviews/avatarview'
JView = require '../jview'
PopupNotifications = require '../notifications/popupnotifications'


module.exports = class AvatarArea extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data)->

    options.cssClass or= 'avatar-area'

    super options, data

    { mainView } = kd.singletons
    account      = @getData()

    @avatar = new AvatarView
      tagName    : 'div'
      cssClass   : 'avatar-image-wrapper'
      attributes :
        title    : 'View your public profile'
      size       :
        width    : 25
        height   : 25
    , account

    @accountPopup = new AccountPopup

    @accountIcon = new AvatarAreaIconLink
      cssClass   : 'acc-dropdown-icon'
      attributes :
        title    : 'Account'
        testpath : 'AvatarAreaIconLink'
      delegate   : @accountPopup

    @notificationsPopup = new PopupNotifications
      cssClass : 'notification-list'

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

    {profile} = @getData()

    """
    {{> @avatar}}
    <a class='profile' href='/#{profile.nickname}' title='Your profile'>#{profile.firstName}</a>
    {{> @accountIcon}}
    {{> @notificationsIcon}}
    """
