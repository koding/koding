globals = require 'globals'
kookies = require 'kookies'
Promise = require 'bluebird'
$ = require 'jquery'
kd = require 'kd'
KDCustomHTMLView = kd.CustomHTMLView
KDListViewController = kd.ListViewController
KDView = kd.View
isLoggedIn = require '../util/isLoggedIn'
showError = require '../util/showError'
whoami = require '../util/whoami'
AvatarPopup = require './avatarpopup'
CustomLinkView = require '../customlinkview'
HelpSupportModal = require '../commonviews/helpsupportmodal'
PopupGroupListItem = require '../popupgrouplistitem'
PopupGroupListItemPending = require './popupgrouplistitempending'
PopupList = require './popuplist'
trackEvent = require 'app/util/trackEvent'


module.exports = class AvatarPopupGroupSwitcher extends AvatarPopup

  constructor:->
    @notLoggedInMessage = 'Login required to switch groups'
    super

  viewAppended:->

    super

    @pending             = 0
    @notPopulated        = yes
    @notPopulatedPending = yes
    groupsController     = kd.getSingleton "groupsController"
    router               = kd.getSingleton "router"

    @_popupList = new PopupList
      itemClass  : PopupGroupListItem

    @_popupListPending = new PopupList
      itemClass  : PopupGroupListItemPending

    # does not work yet
    # @_popupListPending.on 'PendingCountDecreased', @bound 'decreasePendingCount'
    # @_popupListPending.on 'UpdateGroupList',       @bound 'populateGroups'
    # whoami().on        'NewPendingInvitation',  @bound 'populatePendingGroups'

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

    {entryPoint} = globals.config
    createGroupLink = new KDCustomHTMLView
      tagName    : 'a'
      attributes : href : '/Pricing/Team'
      cssClass   : 'bottom'
      partial    : 'Create a group'
      click      : (event)=>
        kd.utils.stopDOMEvent event
        router.handleRoute '/Pricing/CreateGroup', entryPoint : 'koding'
        @hide()

    kd.singletons.mainController.ready ->
      return unless isLoggedIn()
      kd.singleton("paymentController").fetchSubscriptionsWithPlans tags: ["custom-plan"], (err, subscriptions) ->
        return showError err  if err
        createGroupLink.show()   unless subscriptions.length

    backToKoding = new KDCustomHTMLView
      tagName    : 'a'
      attributes : href : '/'
      cssClass   : 'bottom bb'
      partial    : 'Go back to Koding'
      click      : (event)=>
        kd.utils.stopDOMEvent event
        global.location.href = '/'

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
      kd.utils.stopDOMEvent event
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
    #   mousemove  : kd.utils.stopDOMEvent

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Upgrade plan'
      href       : '/Pricing'
      cssClass   : 'bottom-separator'
      click      : (event)=>
        kd.utils.stopDOMEvent event
        router.handleRoute '/Pricing'
        @hide()

        trackEvent 'Account upgrade plan, click',
          category : 'userInteraction'
          action   : 'clicks'
          label    : 'settingsUpgradePlan'

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Koding University'
      href       : 'http://learn.koding.com'
      target     : '_blank'

    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Contact support'
      cssClass   : 'bottom-separator support'
      click      : (event)=>
        kd.utils.stopDOMEvent event
        new HelpSupportModal
        @hide()

        trackEvent 'Contact support, click',
          category : 'userInteraction'
          action   : 'formsubmits'
          label    : 'contactKodingSupport'


    @avatarPopupContent.addSubView new CustomLinkView
      title      : 'Account Settings'
      href       : '/Account'
      attributes :
        testpath : 'AccountSettingsLink'
      cssClass   : 'bottom-separator'
      click      : (event)=>
        kd.utils.stopDOMEvent event
        router.handleRoute '/Account'
        @hide()


    # @avatarPopupContent.addSubView new KDCustomHTMLView
    #   tagName    : 'a'
    #   attributes : href : '/Optout'
    #   cssClass   : 'bottom-separator'
    #   partial    : 'Use "old" Koding'
    #   click      : (event)=>
    #     kookies.set 'useOldKoding', 'true'
    #     location.reload()

    # @avatarPopupContent.addSubView new KDCustomHTMLView
    #   tagName    : 'a'
    #   partial    : 'Environments'
    #   click      : (event)=>
    #     kd.utils.stopDOMEvent event
    #     kd.getSingleton("router").handleRoute "/Environments"
    #     @hide()

    # @avatarPopupContent.addSubView new KDCustomHTMLView
    #   tagName    : 'a'
    #   partial    : 'System health check'
    #   click      : (event)=>
    #     new TroubleshootModal
    #     @hide()


    @avatarPopupContent.addSubView dashboardLink = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "bottom hidden"
      partial  : "Group Dashboard"
      click    : (event) =>
        kd.utils.stopDOMEvent event
        kd.getSingleton("router").handleRoute "/Dashboard"
        @hide()

    @avatarPopupContent.addSubView adminLink = new KDCustomHTMLView
      tagName  : "a"
      cssClass : "bottom hidden"
      partial  : "Team Settings"
      click    : (event) =>
        kd.utils.stopDOMEvent event
        kd.getSingleton("router").handleRoute "/Admin"
        @hide()

    # FIXME:
    groupsController.ready ->
      group = groupsController.getCurrentGroup()
      group.canEditGroup (err, success)=>
        kd.utils.defer => setGroupWrapperStyle()
        return  unless success
        dashboardLink.show()
        adminLink.show()

    cookieName = "kdproxy-usehttp"
    if (kookies.get cookieName) is "1"
      @avatarPopupContent.addSubView new KDCustomHTMLView
        tagName    : 'a'
        partial    : 'Switch back to secure (https) mode'
        click      : (event)=>
          kd.utils.stopDOMEvent event
          kookies.expire cookieName
          global.location.reload()

    @avatarPopupContent.addSubView new KDCustomHTMLView
      tagName    : 'a'
      attributes :
        href     : '/Logout'
        testpath : 'logout-link'
      partial    : 'Logout'
      click      : (event)=>
        kd.utils.stopDOMEvent event
        router.handleRoute '/Logout'
        @hide()

  populatePendingGroups:->
    @listControllerPending.removeAllItems()
    @listControllerPending.hideLazyLoader()

    return  unless isLoggedIn()

    whoami().fetchGroupsWithPendingInvitations (err, groups)=>
      if err then kd.warn err
      else if groups?
        @pending = 0
        for group in groups when group
          @listControllerPending.addItem {group, roles:[], admin:no}
          @pending++
        @updatePendingCount()
        @notPopulatedPending = no


  populateGroups:->
    return  if not isLoggedIn() or @isLoading

    @listController.removeAllItems()

    @isLoading = yes

    whoami().fetchGroups null, (err, groups)=>
      if err then kd.warn err
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

    @emit 'AvatarPopupShouldBeHidden'
