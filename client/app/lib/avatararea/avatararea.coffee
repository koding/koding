kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
AvatarAreaIconLink = require './avatarareaiconlink'
AvatarPopupGroupSwitcher = require './avatarpopupgroupswitcher'
AvatarView = require '../commonviews/avatarviews/avatarview'
JView = require '../jview'
PopupNotifications = require '../notifications/popupnotifications'


module.exports = class AvatarArea extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data)->

    options.cssClass or= 'avatar-area'

    super options, data

    account = @getData()

    @avatar = new AvatarView
      tagName    : 'div'
      cssClass   : 'avatar-image-wrapper'
      attributes :
        title    : 'View your public profile'
      size       :
        width    : 25
        height   : 25
    , account

    @groupSwitcherPopup = new AvatarPopupGroupSwitcher
      cssClass : "group-switcher"

    @groupsSwitcherIcon = new AvatarAreaIconLink
      cssClass   : 'groups acc-dropdown-icon'
      attributes :
        title    : 'Your groups'
        testpath : 'AvatarAreaIconLink'
      delegate   : @groupSwitcherPopup

    @notificationsPopup = new PopupNotifications
      cssClass : "notification-list"

    @notificationsIcon = new AvatarAreaIconLink
      cssClass   : 'notifications acc-notification-icon'
      attributes :
        title    : 'Notifications'
      delegate   : @notificationsPopup

    @once 'viewAppended', =>
      mainView = kd.getSingleton 'mainView'
      mainView.addSubView @groupSwitcherPopup
      mainView.addSubView @notificationsPopup
      @groupSwitcherPopup.listControllerPending.on 'PendingGroupsCountDidChange', (count)=>
        if count > 0
        then @groupSwitcherPopup.invitesHeader.show()
        else @groupSwitcherPopup.invitesHeader.hide()
        @groupsSwitcherIcon.updateCount count

      @attachListeners()

    kd.getSingleton('mainController').on 'accountChanged', =>
      @groupSwitcherPopup.listController.removeAllItems()

      # Commenting out these lines because of
      # removal of the groups links from avatar popup. ~Umut
      # @groupSwitcherPopup.populateGroups()
      # @groupSwitcherPopup.populatePendingGroups()

  attachListeners:->

    @notificationsPopup.on 'NotificationCountDidChange', (count)=>
      kd.utils.killWait @notificationsPopup.loaderTimeout
      @notificationsIcon.updateCount count


  pistachio: ->

    {profile} = @getData()

    """
    {{> @avatar}}
    <a class='profile' href='/#{profile.nickname}' title='Your profile'>#{profile.firstName}</a>
    {{> @groupsSwitcherIcon}}
    {{> @notificationsIcon}}
    """
