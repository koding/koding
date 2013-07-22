class AvatarPopupGroupSwitcher extends AvatarPopup

  constructor:->
    @notLoggedInMessage = 'Login required to switch groups'
    super

  viewAppended:->

    super

    @pending = 0
    @notPopulated = yes
    @notPopulatedPending = yes

    @_popupList = new PopupList
      itemClass  : PopupGroupListItem

    @_popupListPending = new PopupList
      itemClass  : PopupGroupListItemPending

    @_popupListPending.on 'PendingCountDecreased', @bound 'decreasePendingCount'
    @_popupListPending.on 'UpdateGroupList',       @bound 'populateGroups'
    # does not work
    # KD.whoami().on        'NewPendingInvitation',  @bound 'populatePendingGroups'

    @listControllerPending = new KDListViewController
      view                : @_popupListPending
      startWithLazyLoader : yes

    @listController = new KDListViewController
      view                : @_popupList
      startWithLazyLoader : yes

    @listController.on "AvatarPopupShouldBeHidden", @bound 'hide'

    @avatarPopupContent.addSubView @invitesHeader = new KDView
      height   : "auto"
      cssClass : "sublink top hidden"
      partial  : "You have pending group invitations:"

    @avatarPopupContent.addSubView @listControllerPending.getView()

    @avatarPopupContent.addSubView @switchToTitle = new KDView
      height   : "auto"
      cssClass : "sublink top"
      partial  : "Switch to:"

    @switchToTitle.addSubView new KDCustomHTMLView
      tagName    : 'span'
      cssClass   : 'icon help'
      tooltip    :
        title    : "Here you'll find the groups that you are a member of, clicking one of them will take you to a new browser tab."

    @avatarPopupContent.addSubView @listController.getView()

    seeAllView = new KDView
      height   : "auto"
      cssClass : "split sublink"
      partial  : "<a href='#'>See all groups...</a>"
      click    : =>
        KD.getSingleton('router').handleRoute '/Groups'
        @hide()

    backToKodingView = new KDView
      height   : "auto"
      cssClass : "split sublink right"
      partial  : "<a class='right' target='_blank' href='/Activity'>Back to Koding</a>"
      click    : =>
        @hide()

    split = new SplitView
      domId     : "avatararea-bottom-split-view"
      height    : "37px"
      sizes     : [130,null]
      views     : [seeAllView,backToKodingView]
      resizable : no

    @avatarPopupContent.addSubView split

  populatePendingGroups:->
    @listControllerPending.removeAllItems()
    @listControllerPending.hideLazyLoader()

    return  unless KD.isLoggedIn()

    KD.whoami().fetchPendingGroupInvitations (err, groups)=>
      if err then warn err
      else if groups?
        @pending = 0
        for group in groups when group
          @listControllerPending.addItem {group, roles:[], admin:no}
          @pending++
        @updatePendingCount()
        @notPopulatedPending = no

  populateGroups:->
    @listController.removeAllItems()
    @listController.showLazyLoader()

    return  unless KD.isLoggedIn()

    KD.whoami().fetchGroups (err, groups)=>
      if err then warn err
      else if groups?

        stack = []
        groups.forEach (group)->
          stack.push (cb)->
            group.group.fetchMyRoles (err, roles)->
              group.admin = no
              unless err
                group.admin = 'admin' in roles
              cb err, group

        async.parallel stack, (err, results)=>
          unless err
            results.sort (a, b)->
              if a.admin == b.admin
                return a.group.slug > b.group.slug
              else
                return not a.admin and b.admin
            @listController.hideLazyLoader()
            @listController.instantiateListItems results


  decreasePendingCount:->
    @pending--
    @updatePendingCount()

  updatePendingCount:->
    @listControllerPending.emit 'PendingGroupsCountDidChange', @pending

  show:->
    super
    # in case user opens popup earlier than timed out initial population
    @populateGroups() if @notPopulated
    @populatePendingGroups() if @notPopulatedPending

class PopupGroupListItem extends KDListItemView

  constructor:(options = {}, data)->
    options.tagName or= "li"
    super

    {group:{title, avatar, slug}, roles, admin} = @getData()

    roleClasses = roles.map((role)-> "role-#{role}").join ' '
    @setClass "role #{roleClasses}"

    @switchLink = new CustomLinkView
      title       : title
      href        : "/#{if slug is 'koding' then '' else slug+'/'}Activity"
      target      : slug
      icon        :
        cssClass  : 'new-page'
        placement : 'right'
        tooltip   :
          title   : "Opens in a new browser window."
          delayIn : 300

    @adminLink = new CustomLinkView
      title       : ''
      href        : "/#{if slug is 'koding' then '' else slug+'/'}Dashboard"
      target      : slug
      cssClass    : 'fr'
      iconOnly    : yes
      icon        :
        cssClass  : 'dashboard-page'
        placement : 'right'
        tooltip   :
          title   : "Opens admin dashboard in new browser window."
          delayIn : 300
    unless admin
      @adminLink.hide()

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    <div class='right-overflow'>
      {{> @switchLink}}
      {{> @adminLink}}
    </div>
    """

class PopupGroupListItemPending extends PopupGroupListItem

  constructor:(options = {}, data)->
    super

    {group} = @getData()
    @setClass 'role pending'

    @acceptButton = new KDButtonView
      style       : 'clean-gray'
      title       : 'Accept Invitation'
      icon        : yes
      iconOnly    : yes
      iconClass   : 'accept'
      tooltip     :
        title     : 'Accept Invitation'
      callback    : =>
        KD.whoami().acceptInvitation group, (err)=>
          if err then warn err
          else
            @destroy()
            @parent.emit 'PendingCountDecreased'
            @parent.emit 'UpdateGroupList'

    @ignoreButton = new KDButtonView
      style       : 'clean-gray'
      title       : 'Ignore Invitation'
      icon        : yes
      iconOnly    : yes
      iconClass   : 'ignore'
      tooltip     :
        title     : 'Ignore Invitation'
      callback    : =>
        KD.whoami().ignoreInvitation group, (err)=>
          if err then warn err
          else
            new KDNotificationView
              title    : 'Ignored!'
              content  : 'If you change your mind, you can request access to the group anytime.'
              duration : 2000
            @destroy()
            @parent.emit 'PendingCountDecreased'

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    <div class='right-overflow'>
      <div class="buttons">
        {{> @acceptButton}}
        {{> @ignoreButton}}
      </div>
      {{> @switchLink}}
    </div>
    """
