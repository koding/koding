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
      delegate   : @groupSwitcherPopup

    @once 'viewAppended', =>
      mainView = KD.getSingleton 'mainView'
      mainView.addSubView @groupSwitcherPopup
      @groupSwitcherPopup.listControllerPending.on 'PendingGroupsCountDidChange', (count)=>
        if count > 0
        then @groupSwitcherPopup.invitesHeader.show()
        else @groupSwitcherPopup.invitesHeader.hide()
        @groupsSwitcherIcon.updateCount count

    KD.getSingleton('mainController').on 'accountChanged', =>
      @groupSwitcherPopup.listController.removeAllItems()

      # Commenting out these lines because of
      # removal of the groups links from avatar popup. ~Umut
      # @groupSwitcherPopup.populateGroups()
      # @groupSwitcherPopup.populatePendingGroups()


  pistachio: ->

    {profile} = @getData()

    """
    {{> @avatar}}
    <a class='profile' href='/#{profile.nickname}' title='Your profile'>#{profile.firstName}</a>
    {{> @groupsSwitcherIcon}}
    """

