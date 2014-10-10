class AvatarArea extends KDCustomHTMLView

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
        width    : 35
        height   : 35
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
      mainView = KD.getSingleton 'mainView'
      mainView.addSubView @groupSwitcherPopup
      mainView.addSubView @notificationsPopup
      @groupSwitcherPopup.listControllerPending.on 'PendingGroupsCountDidChange', (count)=>
        if count > 0
        then @groupSwitcherPopup.invitesHeader.show()
        else @groupSwitcherPopup.invitesHeader.hide()
        @groupsSwitcherIcon.updateCount count

      @attachListeners()

    KD.getSingleton('mainController').on 'accountChanged', =>
      @groupSwitcherPopup.listController.removeAllItems()

      # Commenting out these lines because of
      # removal of the groups links from avatar popup. ~Umut
      # @groupSwitcherPopup.populateGroups()
      # @groupSwitcherPopup.populatePendingGroups()

  attachListeners:->

    @notificationsPopup.on 'NotificationCountDidChange', (count)=>
      @utils.killWait @notificationsPopup.loaderTimeout
      @notificationsIcon.updateCount count


  pistachio: ->

    {profile} = @getData()

    """
    {{> @avatar}}
    <a class='profile' href='/#{profile.nickname}' title='Your profile'>#{profile.firstName}</a>
    {{> @groupsSwitcherIcon}}
    {{> @notificationsIcon}}
    """

