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
helpers            = require './helpers'
isSoloProductLite  = require 'app/util/issoloproductlite'

module.exports = class AvatarArea extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data) ->

    options.cssClass or= 'avatar-area'

    super options, data

    if isKoding()
      if isSoloProductLite()
      then @createLiteSoloViews()
      else @createSoloViews()
    else
      @createTeamViews()


  createLiteSoloViews: ->

    { mainView } = kd.singletons
    account      = @getData()

    @accountPopup = new AccountPopup

    @avatar = new AvatarStaticView
      cssClass   : 'avatar-image-wrapper'
      attributes :
        title    : 'View your notifications and account settings'
      size       :
        width    : 25
        height   : 25
    , account

    @profileName = new JCustomHTMLView
      tagName    : 'a'
      cssClass   : 'profile'
      attributes :
        href     : '#'
        title    : 'Your profile'
      pistachio  : '{{ #(profile.firstName) }}'
    , account

    @accountIcon = new AvatarAreaIconLink
      cssClass   : 'acc-dropdown-icon'
      attributes :
        title    : 'Account'
        testpath : 'AvatarAreaIconLink'

    helpers.makePopupButton @accountIcon, @accountPopup

    @once 'viewAppended', -> mainView.addSubView @accountPopup


  createSoloViews: ->

    { mainView } = kd.singletons
    account      = @getData()
    { profile }  = account

    @notificationsPopup = new PopupNotifications
      cssClass : 'notification-list'

    @accountPopup = new AccountPopup

    @avatar = new AvatarView
      cssClass   : 'avatar-image-wrapper'
      attributes :
        title    : 'View your public profile'
      size       :
        width    : 25
        height   : 25
    , account

    @profileName = new JCustomHTMLView
      tagName    : 'a'
      cssClass   : 'profile'
      attributes :
        href     : "/#{profile.nickname}"
        title    : 'Your profile'
      pistachio  : '{{ #(profile.firstName) }}'
    , account

    @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'notifications acc-notification-icon'
      attributes :
        title    : 'Notifications'
        href     : '#'

    @accountIcon = new AvatarAreaIconLink
      cssClass   : 'acc-dropdown-icon'
      attributes :
        title    : 'Account'
        testpath : 'AvatarAreaIconLink'

    helpers.makePopupButton @notificationsIcon, @notificationsPopup
    helpers.makePopupButton @accountIcon, @accountPopup

    @once 'viewAppended', ->
      mainView.addSubView @accountPopup
      mainView.addSubView @notificationsPopup
      @bindNotificationsPopupEvents()


  createTeamViews: ->

    { mainView } = kd.singletons
    account      = @getData()

    @notificationsPopup = new PopupNotifications
      cssClass : 'notification-list team'

    @avatar = new AvatarStaticView
      cssClass   : 'avatar-image-wrapper'
      attributes :
        title    : 'View your notifications and account settings'
      size       :
        width    : 25
        height   : 25
    , account

    @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'notifications acc-notification-icon'
      attributes :
        title    : 'Notifications'
        href     : '#'

    helpers.makePopupButton @avatar, @notificationsPopup

    @once 'viewAppended', ->
      mainView.addSubView @notificationsPopup
      @bindNotificationsPopupEvents()


  bindNotificationsPopupEvents: ->

    @notificationsPopup.on 'NotificationCountDidChange', (count) =>
      kd.utils.killWait @notificationsPopup.loaderTimeout
      @notificationsIcon.updateCount count


  pistachio: ->

    if isKoding() and isSoloProductLite()
      '''
      {{> @avatar}}
      {{> @profileName}}
      {{> @accountIcon}}
      '''
    else if isKoding()
      '''
      {{> @avatar}}
      {{> @profileName}}
      {{> @notificationsIcon}}
      {{> @accountIcon}}
      '''
    else
      '''
      {{> @avatar}}
      {{> @notificationsIcon}}
      '''
