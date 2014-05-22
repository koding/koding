class AvatarArea extends KDCustomHTMLView

  JView.mixin @prototype

  constructor: (options = {}, data)->

    options.cssClass or= 'avatar-area'

    super options, data

    account = @getData()

    @avatar = new AvatarView
      tagName    : "div"
      cssClass   : "avatar-image-wrapper"
      attributes :
        title    : "View your public profile"
      size       :
        width    : 25
        height   : 25
    , account

    @profileLink = new ProfileLinkView {}, account

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
      @groupSwitcherPopup.populateGroups()
      @groupSwitcherPopup.populatePendingGroups()

  pistachio: ->
    """
    {{> @avatar}}
    <section>
      <h2>{{> @profileLink}}</h2>
      <h3>@{{#(profile.nickname)}}</h3>
      {{> @groupsSwitcherIcon}}
    </section>
    """