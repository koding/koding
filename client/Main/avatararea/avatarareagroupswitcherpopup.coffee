class AvatarPopupGroupSwitcher extends AvatarPopup

  constructor:->
    @notLoggedInMessage = 'Login required to switch groups'
    super

  viewAppended:->

    super

    @pending             = 0
    @notPopulated        = yes
    @notPopulatedPending = yes
    groupsController     = KD.getSingleton "groupsController"
    router               = KD.getSingleton "router"


    @_popupList = new PopupList
      itemClass  : PopupGroupListItem

    @_popupListPending = new PopupList
      itemClass  : PopupGroupListItemPending

    # does not work yet
    # @_popupListPending.on 'PendingCountDecreased', @bound 'decreasePendingCount'
    # @_popupListPending.on 'UpdateGroupList',       @bound 'populateGroups'
    # KD.whoami().on        'NewPendingInvitation',  @bound 'populatePendingGroups'

    @listControllerPending = new KDListViewController
      lazyLoaderOptions   :
        partial           : ''
        spinnerOptions    :
          loaderOptions   :
            color         : '#ffffff'
          size            :
            width         : 32
      view                : @_popupListPending

    @listController = new KDListViewController
      lazyLoaderOptions   :
        partial           : ''
        spinnerOptions    :
          loaderOptions   :
            color         : '#ffffff'
          size            :
            width         : 32
      view                : @_popupList

    @listController.on "AvatarPopupShouldBeHidden", @bound 'hide'

    @avatarPopupContent.addSubView @invitesHeader = new KDView
      height   : "auto"
      cssClass : "sublink hidden"
      partial  : "You have pending group invitations:"

    @addSubView @groupSubMenuWrapper = new KDCustomHTMLView
      partial  : '<div class="kdview content"></div>'
      cssClass : 'avatararea-popup submenu' # this is a hack, just to use the same position w/ notifications dropdown

    setGroupWrapperStyle = =>
      @groupSubMenuWrapper.setStyle
        bottom : @getHeight() + 2
        left   : 257

    {entryPoint} = KD.config
    createGroupLink = new KDCustomHTMLView
      tagName    : 'a'
      attributes : href : '/Pricing/Team'
      cssClass   : 'bottom'
      partial    : 'Create a group'
      click      : (event)=>
        KD.utils.stopDOMEvent event
        router.handleRoute '/Pricing/CreateGroup', entryPoint : 'koding'
        @hide()

    KD.singletons.mainController.ready ->
      return unless KD.isLoggedIn()
      KD.singleton("paymentController").fetchSubscriptionsWithPlans tags: ["custom-plan"], (err, subscriptions) ->
        return KD.showError err  if err
        createGroupLink.show()   unless subscriptions.length

    backToKoding = new KDCustomHTMLView
      tagName    : 'a'
      attributes : href : '/'
      cssClass   : 'bottom bb'
      partial    : 'Go back to Koding'
      click      : (event)=>
        KD.utils.stopDOMEvent event
        location.href = '/'

    groupsController.ready ->
      backToKoding.destroy()  if groupsController.getCurrentGroup().slug is 'koding'

    @groupSubMenuWrapper.addSubView createGroupLink, '.content'
    @groupSubMenuWrapper.addSubView backToKoding, '.content'
    @groupSubMenuWrapper.addSubView @listControllerPending.getView(), '.content'
    @groupSubMenuWrapper.addSubView @listController.getView(), '.content'


    submenuShown = no

    @avatarPopupContent.bindEvent 'mousemove'
    @avatarPopupContent.on 'mousemove', (event)=>
      return  if $(event.target).closest().is '.submenu'
      @groupSubMenuWrapper.unsetClass 'active'

    handleSubMenu = (event)=>
      KD.utils.stopDOMEvent event
      submenuShown = yes
      @groupSubMenuWrapper.setClass 'active'

      # Commenting out these lines because of
      # removal of the groups links from avatar popup. ~Umut
      # @populateGroups()

    # @avatarPopupContent.addSubView new KDCustomHTMLView
    #   tagName    : 'a'
    #   attributes : href : '#'
    #   partial    : 'Your groups'
    #   bind       : 'mouseenter mousemove'
    #   mouseenter : handleSubMenu
    #   click      : handleSubMenu
    #   mousemove  : KD.utils.stopDOMEvent

    @avatarPopupContent.addSubView new KDCustomHTMLView
      tagName    : 'a'
      attributes : href : '/Account'
      cssClass   : 'bottom-separator'
      partial    : 'Account settings'
      click      : (event)=>
        KD.utils.stopDOMEvent event
        router.handleRoute '/Account'
        @hide()

    # @avatarPopupContent.addSubView new KDCustomHTMLView
    #   tagName    : 'a'
    #   partial    : 'Environments'
    #   click      : (event)=>
    #     KD.utils.stopDOMEvent event
    #     KD.getSingleton("router").handleRoute "/Environments"
    #     @hide()

    @avatarPopupContent.addSubView new KDCustomHTMLView
      tagName    : 'a'
      partial    : 'System health check'
      click      : (event)=>
        new TroubleshootModal
        @hide()

    @avatarPopupContent.addSubView dashboardLink = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "bottom hidden"
      partial  : "Group dashboard"
      click    : (event) =>
        KD.utils.stopDOMEvent event
        KD.getSingleton("router").handleRoute "/Dashboard"
        @hide()

    # FIXME:
    groupsController.ready ->
      group = groupsController.getCurrentGroup()
      group.canEditGroup (err, success)=>
        KD.utils.defer => setGroupWrapperStyle()
        return  unless success
        dashboardLink.show()

    cookieName = "kdproxy-usehttp"
    if (Cookies.get cookieName) is "1"
      @avatarPopupContent.addSubView new KDCustomHTMLView
        tagName    : 'a'
        partial    : 'Switch back to secure (https) mode'
        click      : (event)=>
          KD.utils.stopDOMEvent event
          Cookies.expire cookieName
          window.location.reload()

    @avatarPopupContent.addSubView new KDCustomHTMLView
      tagName    : 'a'
      attributes : href : '/Logout'
      partial    : 'Logout'
      click      : (event)=>
        KD.utils.stopDOMEvent event
        router.handleRoute '/Logout'
        @hide()

  populatePendingGroups:->
    @listControllerPending.removeAllItems()
    @listControllerPending.hideLazyLoader()

    return  unless KD.isLoggedIn()

    KD.whoami().fetchGroupsWithPendingInvitations (err, groups)=>
      if err then warn err
      else if groups?
        @pending = 0
        for group in groups when group
          @listControllerPending.addItem {group, roles:[], admin:no}
          @pending++
        @updatePendingCount()
        @notPopulatedPending = no


  populateGroups:->
    return  if not KD.isLoggedIn() or @isLoading

    @listController.removeAllItems()

    @isLoading = yes

    KD.whoami().fetchGroups null, (err, groups)=>
      if err then warn err
      else if groups?

        results = []
        promises = groups.map (group)->
          new Promise (resolve, reject)->
            group.group.fetchMyRoles (err, roles)->
              group.admin = unless err then 'admin' in roles else no
              results.push group
              resolve()

        Promise.all(promises).then =>

          @isLoading = no

          results.sort (a, b)->
            return if a.admin is b.admin
            then a.group.slug > b.group.slug
            else not a.admin and b.admin

          index = null
          results.forEach (item, i)->
            index = i  if item.group.slug is 'koding'

          results.splice index, 1  if index?

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

    # Commenting out these lines because of
    # removal of the groups links from avatar popup. ~Umut
    # @populateGroups() if @notPopulated
    # @populatePendingGroups() if @notPopulatedPending

  hide:->
    super
    @groupSubMenuWrapper.unsetClass 'active'

class PopupGroupListItem extends KDListItemView

  JView.mixin @prototype

  constructor:(options = {}, data)->
    options.tagName or= "li"
    options.type    or= "activity-ticker-item"
    super

    {group:{title, avatar, slug, customize}, roles, admin} = @getData()
    roleClasses = roles.map((role)-> "role-#{role}").join ' '
    @setClass "role #{roleClasses}"

    defaultLogo  = "https://koding.s3.amazonaws.com/grouplogo_.png"

    @groupLogo  = new KDCustomHTMLView
      tagName    : "figure"
      cssClass   : "avatararea-group-logo"

    @switchLink = new CustomLinkView
      title       : title
      cssClass    : "avatararea-group-name"
      href        : "/#{if slug is KD.defaultSlug then '' else slug+'/'}Activity"
      target      : slug

    @adminLink = if admin
      new CustomLinkView
        title       : ''
        href        : "/#{if slug is KD.defaultSlug then '' else slug+'/'}Dashboard"
        target      : slug
        cssClass    : 'admin-icon'
        iconOnly    : yes
        icon        :
          cssClass  : 'dashboard-page'
          placement : 'right'
          tooltip   :
            title   : "Opens admin dashboard in new browser window."
            delayIn : 300
    else new KDCustomHTMLView

  pistachio: ->
    {group} = @getData()
    {slug, customize} = group

    if customize?.logo
      @groupLogo.setCss 'background-image', "url(#{customize?.logo})"
    else
      @groupLogo.setCss 'background-color', KD.utils.stringToColor slug

    """
    {{> @groupLogo}}{{> @switchLink}}{{> @adminLink}}
    """

class PopupGroupListItemPending extends PopupGroupListItem

  JView.mixin @prototype

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
