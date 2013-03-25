class StaticProfileController extends KDController

  CONTENT_TYPES = [
    'CBlogPostActivity','CStatusActivity','CCodeSnipActivity',
    'CDiscussionActivity', 'CTutorialActivity'
  ]

  constructor:(options,data)->
    super options,data

    console.time 'StaticProfileController'

    appManager = @getSingleton 'appManager'

    @navLinks     = {}
    @controllers  = {}
    @wrappers     = {}

    @profileUser  = null
    @registerSingleton 'staticProfileController', @, yes

    @reviveViewsOnPageLoad()
    @addEventListeners()

    @mainController = @getSingleton 'mainController'
    @lazyDomController = @getSingleton('lazyDomController')

    # KD.remote.cacheable KD.config.profileEntryPoint, (err, user, name)=>
    # FIXME - we want to use cacheable, not a JAccount call, but names
    # are not working correctly

    KD.remote.api.JAccount.one
      "profile.nickname" : KD.config.profileEntryPoint
    , (err, user, name)=>
      if err then log err,user,name
      unless err
        @reviveViewsOnUserLoad user

  addLogic:(type,lockSidebar=no,displaySidebar=yes)->
      unless @controllers[type]?
        @addLogicForType type, =>
          # @showWrapper @wrappers[type]
          @controllers[type]?.hideLazyLoader()
      else
        @controllers[type]?.hideLazyLoader()
        @showWrapper @wrappers[type]

      @displaySidebar displaySidebar

  displaySidebar:(show=yes,delay=250)->
    @utils.wait delay, =>
      @profileContentList["#{if show then '' else 'un'}setClass"] 'has-links'
      @profileContentLinks["#{if show then 'un' else ''}setClass"] 'links-hidden'

  addEventListeners:->

    @on 'CommentLinkReceivedClick', (view)=>
      if KD.whoami() instanceof KD.remote.api.JGuest
        new  KDNotificationView
          title : "Please log in to see this post and it's comments"

        @utils.wait 1000, =>
          @mainController.loginScreen.animateToForm 'login'
      else
        @lazyDomController.openPath "/#{view.getData().group}/Activity/#{view.getData().slug}"


    @on 'CommentCountReceivedClick', (view)=>
      if KD.whoami() instanceof KD.remote.api.JGuest
        new  KDNotificationView
          title : "Please log in to see this post and it's comments"

        @utils.wait 1000, =>
          @mainController.loginScreen.animateToForm 'login'

      else
        @lazyDomController.openPath "/#{view.getData().group}/Activity/#{view.getData().slug}"

    @on 'StaticInteractionHappened',(view)=>
      if KD.whoami() instanceof KD.remote.api.JGuest

        if view instanceof LikeView
          new KDNotificationView
            title : 'Please log in to like this post.'
        else if view instanceof StaticTagLinkView
          new  KDNotificationView
            title : 'Please log in to see this Topic'

        @utils.wait 1000, =>
          @mainController.loginScreen.animateToForm 'login'

      else
        if view instanceof LikeView
        else if view instanceof StaticTagLinkView
          @lazyDomController.openPath "/#{view.getData().group}/Topics/#{view.getData().slug}"


    @on 'HomeLinkClicked', =>

      @addLogic 'static', no, no

      # HERE is the place to implement custom profile splash screens, reveal.js and such

      @staticDefaultItem.show()
      # @showLoadingBar()
      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity', 'static', =>
        @showWrapper @wrappers['static']
        @staticDefaultItem.show()


    @on 'ActivityLinkClicked', (path)=>
      @addLogic 'activity', yes, yes
      @showLoadingBar()
      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity', 'activity', =>
        @showWrapper @wrappers['activity']


    @on 'AboutLinkClicked', (path)=>
      @addLogic 'about', yes, no


    @on 'CustomizeLinkClicked',=>

      return if KD.whoami().getId() isnt @profileUser.getId()

      @avatarAreaIconMenu.emit 'CustomizeLinkClicked'

      # reviving customization

      # @profileTitleNameView.setClass 'edit'
      # @profileTitleBioView.setClass 'edit'

      # @profileTitleView.on 'click', =>
      #   @profileTitleBioInput.hide()
      #   @profileTitleNameView.setClass 'edit'
      #   @profileTitleBioView.setClass 'edit'
      #   no


      return if @customizeViewsAttached
      @customizeViewsAttached = yes

      types = @getAllowedTypes @profileUser

      for type in CONTENT_TYPES
        @navLinks[type].addSubView new StaticNavCheckBox
          activityType : type
          defaultValue : type in types
          delegate     : @
        , @profileUser


    @on 'ShowMoreButtonClicked', =>
      @addStaticLogic()
      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity', 'static', =>
        @showWrapper @staticListWrapper


    @on 'StaticProfileNavLinkClicked', (facets,type,callback=->)=>

      @showLoadingBar() unless type in ['static']

      facets = [facets] if 'string' is typeof facets

      if @profileUser
        allowedTypes = @getAllowedTypes @profileUser

        blockedTypes = facets.reduce (acc, facet)->
          acc.push facet unless facet in allowedTypes
          return acc
        , []

        @emit 'DecorateStaticNavLinks', allowedTypes, facets.first

        if blockedTypes.length is 0
          @currentFacets = facets
          appManager.tell 'Activity', 'fetchActivity',
            originId : @profileUser.getId()
            facets : facets
            bypass : yes
          , (err, activities=[])=>
            @refreshActivities err, activities, type
            callback()
        else @emit 'BlockedTypesRequested', blockedTypes

    @on "LogoClicked", =>
        @profileLogoInfo.unsetClass 'in'
        unless KD.whoami() instanceof KD.remote.api.JGuest
          @profilePersonalWrapperView.setClass 'slide-down'
          @profileContentWrapperView.setClass 'slide-down'
          @profileLogoView.setClass 'top'

          @lazyDomController.hideLandingPage()
        else
          @mainController.loginScreen.animateToForm 'register'

  reviveAdminViews:->

      if @profileTitleNameInput then @profileTitleNameInput.show()
      else
        @profileTitleNameSpan = new KDCustomHTMLView
          tagName       : 'span'
          lazyDomId     : 'profile-name-span'
          cssClass      : 'edit'
          click         : =>
            @profileTitleNameInput.show()
            @utils.defer => @profileTitleNameInput.setFocus()
            @profileTitleNameView.setClass 'edit'


        @profileTitleNameView.addSubView @profileTitleNameInput = new KDHitEnterInputView
          defaultValue  : Encoder.htmlDecode @profileUser.profile.staticPage?.title \
            or "#{@profileUser.profile.firstName} #{@profileUser.profile.lastName}"
          tooltip       :
            placement   : 'bottom'
            direction   : 'right'
            title       : 'Enter your page title and hit enter to save. Leaving this field empty will put your full name as default title.'

          blur          : =>
            @profileTitleNameInput.hide()
            @profileTitleNameView.unsetClass 'edit'

          callback :(value)=>
            value = Encoder.htmlEncode value
            @profileUser.setStaticPageTitle Encoder.XSSEncode(value), =>

              # set to default if empty
              if value is ''
                value = "#{@profileUser.profile.firstName} #{@profileUser.profile.lastName}"
              @profileTitleNameView.unsetClass 'edit'
              @profileTitleNameSpan.updatePartial value
              new KDNotificationView
                title   : 'Title updated.'

      if @profileTitleBioInput
        @profileTitleBioInput.show()
      else
        @profileTitleBioSpan = new KDCustomHTMLView
          tagName       : 'span'
          lazyDomId     : 'profile-bio-span'
          cssClass      : 'edit'
          click         : =>
            @profileTitleBioInput.show()
            @utils.defer => @profileTitleBioInput.setFocus()
            @profileTitleBioView.setClass 'edit'

        @profileTitleBioView.addSubView @profileTitleBioInput = new KDHitEnterInputView
          defaultValue  : Encoder.htmlDecode @profileUser.profile.staticPage?.about \
            or "#{@profileUser.profile.about}"
          tooltip       :
            placement   : 'bottom'
            direction   : 'right'
            title       : 'Enter your page description and hit enter to save. Leaving this field empty will put your bio as default description.'

          blur          : =>
            @profileTitleBioInput.hide()
            @profileTitleBioView.unsetClass 'edit'

          callback :(value)=>
            value = Encoder.htmlEncode value
            @profileUser.setStaticPageAbout Encoder.XSSEncode(value), =>
              @profileTitleBioView.unsetClass 'edit'
              if value is ''
                value = "#{@profileUser.profile.about}"
              @profileTitleBioSpan.updatePartial value
              new KDNotificationView
                title   : 'Description updated.'

  reviveViewsOnPageLoad:->

    console.time 'reviving page elements on pageload.'

    allowedTypes  = ['CBlogPostActivity']
    blockedTypes  = []
    @currentFacets = []
    # reviving the content view. this encapsulates the listitem feed after
    # user input (type selection, more-button)
    @profileContentView = new KDListView
      lazyDomId : 'profile-content'
      itemClass : StaticActivityListItemView
    , {}

    @sanitizeStaticContent @profileContentView

    # reviving the landing page. this is needed to handle window
    # resize events for the view and subviews
    @landingView = new KDView
      lazyDomId : 'static-landing-page'

    @landingView.listenWindowResize()
    @landingView._windowDidResize = =>
      @landingView.setHeight window.innerHeight
      @profileContentView.setHeight window.innerHeight-@profileTitleView.getHeight()
      # @repositionLogoView()

    groupAvatarDrop = new KDView
      lazyDomId : 'landing-page-avatar-drop'
      tooltip   :
        title   : "Click here to go to Koding"
      click     : => @lazyDomController.hideLandingPage()

    @profileTitleView = new KDView
      lazyDomId : 'profile-title'

    @profileShowMoreView = new KDView
      lazyDomId : 'profile-show-more-wrapper'
      cssClass  : 'hidden'

    profileShowMoreButton = new KDButtonView
      lazyDomId : 'profile-show-more-button'
      title     : 'Show more'
      callback  : =>
        @emit 'ShowMoreButtonClicked'
        @profileShowMoreView.hide()
        @profileShowMoreView.setHeight 0
        @landingView._windowDidResize()

    if @profileContentView.$().attr('data-count') > 0
      @profileShowMoreView.show()
    else @profileShowMoreView.hide()

    # reviving wrapper views for resize/slide animations as well as
    # adding administrative views
    @profileContentWrapperView = new KDView
      lazyDomId : 'profile-content-wrapper'
      cssClass  : 'slideable'

    @profilePersonalWrapperView = new KDView
      lazyDomId : 'profile-personal-wrapper'
      cssClass  : 'slideable'
      # bind : 'mouseenter mouseleave'
      click :(event)=>
        unless $(event.target).is 'a'
          @mainController.emit "landingSidebarClicked"

    #
    # allow for sidebar lock here!
    # resize avatar to center or something
    #

    # @profilePersonalWrapperView.on 'mouseenter',(event)=>
    #     @profilePersonalWrapperView.setWidth 160
    #     # @profileContentWrapperView.$().css marginLeft : "160px"

    # @profilePersonalWrapperView.on 'mouseleave',(event)=>
    #   unless @lockSidebar
    #     @profilePersonalWrapperView.setWidth 50
    #     # @profileContentWrapperView.$().css marginLeft : "50px"

    # reviving feed type selectors that will activate feed facets


    @staticDefaultItem = new KDView
      lazyDomId : 'profile-blog-default-item'

    @profileContentLinks = new KDView
      lazyDomId : 'profile-content-links'

    @profileContentList = new KDView
      lazyDomId : 'profile-content-list'

    for type in CONTENT_TYPES
      @navLinks[type] = new StaticNavLink
        delegate  : @
        lazyDomId : type

    @emit 'DecorateStaticNavLinks', allowedTypes, 'CBlogPostActivity'

    # reviving loading bar
    @profileLoadingBar = new KDView
      lazyDomId : 'profile-loading-bar'
      partial   : 'Loading'
    @profileLoadingBar.addSubView @profileLoaderView = new KDLoaderView
      size          :
        width       : 16
        height      : 16
      loaderOptions :
        color       : '#444'
    @profileLoaderView.hide()

    # reviving logo for the slideup animation
    # @profileLogoInfo = new CustomLinkView
    #   title : 'Go to Koding.com'
    #   lazyDomId : 'profile-koding-logo-info'


    # @profileLogoWrapperView = new KDView
    #   lazyDomId: 'profile-koding-logo-wrapper'
    #   bind : 'mouseenter mouseleave'
    #   click :=> @emit 'LogoClicked'

    # @profileLogoView = new KDView
    #   lazyDomId: 'profile-koding-logo'

    # @profileLogoWrapperView.on 'mouseenter', (event)=>
    #     @profileLogoView.setClass 'with-text'
    #     @profileLogoInfo.setClass 'in'

    # @profileLogoWrapperView.on 'mouseleave', (event)=>
    #   @profileLogoView.unsetClass 'with-text'
    #   @profileLogoInfo.unsetClass 'in'

    # @repositionLogoView()

    console.timeEnd 'reviving page elements on pageload.'


  reviveViewsOnUserLoad:(user)->

    console.time 'reviving page elements on userload.'

    @utils.defer => @emit 'HomeLinkClicked'

    @profileUser = user
    @emit 'DecorateStaticNavLinks', @getAllowedTypes(@profileUser), 'CBlogPostActivity'

    @avatarAreaIconMenu = new StaticAvatarAreaIconMenu
      lazyDomId    : 'profile-buttons'
      delegate     : @
    , @profileUser

    @avatarAreaIconMenu.$('.static-profile-button').remove()

    if user.getId() is KD.whoami().getId()

      # reviving admin stuff


      @profileTitleNameView = new KDView
        lazyDomId : 'profile-name'

      @profileTitleBioView = new KDView
        lazyDomId : 'profile-bio'

      profileAdminCustomizeView = new KDView
        lazyDomId : 'profile-admin-customize'

      profileAdminCustomizeView.addSubView staticPageSettingsButton = new CustomLinkView
        title : 'Customize'
        cssClass : 'static-page-settings-button clean-gray'
        click :(event)=>
          @emit 'CustomizeLinkClicked'
          event.stopPropagation()
          event.preventDefault()

      profileAdminCustomizeView.show()

      profileAdminMessageView = new KDView
        lazyDomId : 'profile-admin-message'

      showPage = user.profile.staticPage?.show

      profileAdminMessageView.addSubView disableLink = new CustomLinkView
        title     : "#{if showPage is yes then 'Disable' else 'Enable'}"
        cssClass  : 'message-disable'
        click     : (event)=>
          event?.stopPropagation()
          event?.preventDefault()

          if user.profile.staticPage?.show is yes
            modal           = new KDModalView
              cssClass      : 'disable-static-page-modal'
              title         : 'Do you really want to disable your Public Page?'
              content       : """
                <div class="modalformline">
                  <p>Disabling this feature will disable other people
                  from publicly viewing your profile. You will still be
                  able to access the page yourself.</p>
                  <p>Do you want to continue?</p>
                </div>
                """
              buttons       :
                "Disable the Public Page" :
                  cssClass  : 'modal-clean-red'
                  callback  : =>
                    modal.destroy()
                    user.setStaticPageVisibility no, (err,res)=>
                      if err then log err
                      disableLink.updatePartial 'Enable this Public Page'
                Cancel      :
                  cssClass  : 'modal-cancel'
                  callback  : =>
                    modal.destroy()
          else
            user.setStaticPageVisibility yes, (err,res)=>
              if err then log err
              disableLink.updatePartial 'Disable this Public Page'

      @reviveAdminViews()

    console.timeEnd 'reviving page elements on userload.'
    console.timeEnd 'StaticProfileController'


  appendActivities:(err,activities, type)->
    @controllers[type].listActivities activities
    @controllers[type].hideLazyLoader()

  refreshActivities:(err,activities,type)->
    @profileShowMoreView.hide()

    controller = @controllers[type]
    @wrappers[type].show()

    controller.removeAllItems()
    controller.hideLazyLoader()

    controller.hideNoItemWidget()
    if activities.length > 0
      controller.listActivities activities
    else
      controller.showNoItemWidget() unless type in ['static']


    @hideLoadingBar()

  hideLoadingBar:->
    @profileLoadingBar.unsetClass 'active'
    # @profileLoaderView.hide()

  showLoadingBar:->
    @profileLoadingBar.setClass 'active'
    @profileLoaderView.show()


  getAllowedTypes:(@profileUser)->
    allowedTypes = @profileUser.profile.staticPage?.showTypes or CONTENT_TYPES

  sanitizeStaticContent:(view)->
    view.$(".content-item > .has-markdown > span.data a").each (i,element)->
      $(element).attr target : '_blank'


  addLogicForType:(type,callback=->)->
    switch type
      when 'activity'
       @addActivityLogic callback

      when 'topic'
       @addTopicLogic callback

      when 'group'
       @addGroupsLogic callback

      when 'app'
       @addAppsLogic callback

      when 'member'
       @addMembersLogic callback

      when 'about'
       @addAboutLogic callback

      when 'static'
       @addStaticLogic callback



  addActivityLogic:(callback=->)->
    log 'adding activity logic'
    activityController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : ActivityListItemView
      viewOptions       :
        cssClass        : 'static-content activity-related'
      showHeader        : no
      noItemFoundWidget : new KDCustomHTMLView
        cssClass : "lazy-loader"
        partial  : "So far, #{@profileUser.profile.firstName} has not posted this kind of activity."
      noMoreItemFoundWidget : new KDCustomHTMLView
        cssClass : "lazy-loader"
        partial  : "There is no more activity."

    activityListWrapper = activityController.getView()
    @profileContentView.addSubView activityListWrapper

    activityController.on 'LazyLoadThresholdReached', =>
      appManager.tell 'Activity', 'fetchActivity',
        originId  : @profileUser.getId()
        facets    : @currentFacets
        to        : @activityController.itemsOrdered.last.getData().meta.createdAt
        bypass    : yes
      , (err,activities)=>
        @appendActivities err,activities,'activity'
        @hideLoadingBar()

    @controllers['activity'] = activityController
    @wrappers['activity']    = activityListWrapper

    callback()

  addAboutLogic:(callback=->)->
    log 'adding about logic'

    @showLoadingBar()

    @wrappers['about'] = yes

    if @profileUser
      @profileUser.fetchAbout (err,about)=>
        if err
          log err
        else
          @profileContentView.addSubView aboutWrapper = new StaticProfileAboutView
            about : about
          ,@profileUser

          @hideLoadingBar()

          @wrappers['about'] = aboutWrapper
          @showWrapper aboutWrapper
          callback()


  # addTopicLogic:(callback=->)->
  #   log 'adding topics logic'

  #   topicsController = new ActivityListController
  #     delegate          : @
  #     lazyLoadThreshold : .99
  #     itemClass         : StaticTopicsListItem
  #     viewOptions       :
  #       cssClass        : 'static-content topic'
  #     showHeader        : no

  #   topicsListWrapper = topicsController.getView()
  #   @profileContentView.addSubView topicsListWrapper

  #   topicsController.hideLazyLoader()

  #   @showLoadingBar()
  #   @profileUser.fetchFollowedTopics {},{},(err,topics)=>
  #     if topics
  #       @refreshActivities err, topics, 'topic'
  #     else
  #       topicsController.hideLazyLoader()
  #       @hideLoadingBar()
  #       log 'No topics'

  #   @controllers['topic'] = topicsController
  #   @wrappers['topic']    = topicsListWrapper

  #   callback()


  # addGroupsLogic:(callback=->)->
  #   log 'adding groups logic'

  #   groupsController = new ActivityListController
  #     delegate          : @
  #     lazyLoadThreshold : .99
  #     itemClass         : StaticGroupsListItem
  #     viewOptions       :
  #       cssClass        : 'static-content group'
  #     showHeader        : no

  #   groupsListWrapper = groupsController.getView()
  #   @profileContentView.addSubView groupsListWrapper

  #   @showLoadingBar()
  #   @profileUser.fetchGroups (err,groups)=>
  #     if groups
  #       groupList = (item.group for item in groups)
  #       @refreshActivities err, groupList, 'group'
  #     else
  #       groupsController.hideLazyLoader()
  #       @hideLoadingBar()
  #       log 'No groups'

  #   @controllers['group'] = groupsController
  #   @wrappers['group']    = groupsListWrapper

  #   callback()


  # addAppsLogic:(callback=->)->
  #   log 'adding apps logic'

  #   appsController = new ActivityListController
  #     delegate          : @
  #     lazyLoadThreshold : .99
  #     itemClass         : StaticAppsListItem
  #     viewOptions       :
  #       cssClass        : 'static-content app'
  #     showHeader        : no

  #   appsListWrapper = appsController.getView()
  #   @profileContentView.addSubView appsListWrapper

  #   @showLoadingBar()
  #   KD.remote.api.JApp.some {originId : @profileUser.getId()},{},(err,apps)=>
  #     if apps?.length
  #       @refreshActivities err, apps, 'app'
  #     else
  #       appsController.hideLazyLoader()
  #       @hideLoadingBar()
  #       log 'No apps'

  #   @controllers['app'] = appsController
  #   @wrappers['app']    = appsListWrapper

  #   callback()


  # addMembersLogic:(callback=->)->
  #   log 'adding members logic'

  #   membersController = new ActivityListController
  #     delegate          : @
  #     lazyLoadThreshold : .99
  #     itemClass         : StaticMembersListItem
  #     viewOptions       :
  #       cssClass        : 'static-content member'
  #     showHeader        : no

  #   membersListWrapper = membersController.getView()
  #   @profileContentView.addSubView membersListWrapper

  #   @showLoadingBar()
  #   @profileUser.fetchFollowingWithRelationship {},{},(err, members)=>
  #     if members
  #       @refreshActivities err, members, 'member'
  #     else
  #       membersController.hideLazyLoader()
  #       @hideLoadingBar()
  #       log 'No members'

  #   @controllers['member'] = membersController
  #   @wrappers['member']    = membersListWrapper

  #   callback()


  addStaticLogic:(callback=->)->
    log 'adding static logic'

    staticController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticActivityListItemView
      viewOptions       :
        cssClass        : 'static-content static'
      showHeader        : no

    staticListWrapper = staticController.getView()
    @profileContentView.addSubView staticListWrapper

    staticController.on 'LazyLoadThresholdReached', =>
      appManager.tell 'Activity', 'fetchActivity',
        originId  : @profileUser.getId()
        facets    : ['CBlogPostActivity']
        to        : staticController.itemsOrdered.last.getData().meta.createdAt
        bypass    : yes
      , (err, activities)=>
       @appendActivities err, activities, 'static'

    @controllers['static'] = staticController
    @wrappers['static']    = staticListWrapper

    callback()

  hideWrappers:->
    @profileContentView.$('.content-item.static').remove()
    @staticDefaultItem.hide()
    @profileShowMoreView.hide()

    for own name,wrapper of @wrappers
      wrapper?.hide()

  showWrapper:(wrapper)->
    @hideWrappers()
    # @showHomeLink()
    wrapper.show()

  # setHomeLink:(view)->
  #   @homeLink = view
  #   view.setClass 'invisible'

  # showHomeLink:->
  #   @homeLink.unsetClass 'invisible'



class StaticNavLink extends KDView
  constructor:(options,data)->
    super options,data
    @unsetClass 'disabled'

    @getDelegate().on 'DecorateStaticNavLinks',(allowedTypes,activeType)=>
      @decorate allowedTypes,activeType

  decorate:(allowedTypes,activeType)->
      if @getDomId() in allowedTypes
        @unsetClass 'blocked'
      else
        @setClass 'blocked'

      if @getDomId() is activeType then @setClass 'selected' else @unsetClass 'selected'

  click :->
    @getDelegate().emit 'StaticProfileNavLinkClicked', @getDomId(), 'activity', =>



class StaticNavCheckBox extends KDInputView

  constructorToPluralNameMap =
    'CStatusActivity'     : 'Status Updates'
    'CBlogPostActivity'   : 'Blog Posts'
    'CCodeSnipActivity'   : 'Code Snippets'
    'CDiscussionActivity' : 'Discussions'
    'CTutorialActivity'   : 'Tutorials'

  constructor:(options,data)->
    options.type      = "checkbox"
    options.cssClass  = 'profile-facet-customize-switch'
    options.tooltip   =
      title           : "Check this box to display your #{constructorToPluralNameMap[options.activityType]} on this page"
    super options,data

  click:(event)->
    event.stopPropagation()
    state = @getValue()
    @getData()["#{if state then 'add' else 'remove'}StaticPageType"] @getOption('activityType'), =>
      @getDelegate().emit 'DecorateStaticNavLinks', @getDelegate().getAllowedTypes(@getData())


class StaticHandleLink extends CustomLinkView
  constructor:(options,data)->
    options.cssClass = 'static-handle-link'
    super options,data

  click:(event)->
    if @$().hasClass 'edit'
      event.stopPropagation()
      event.preventDefault()

  pistachio:->
    options = @getOptions()
    data    = @getData()

    data.title ?= options.attributes.href
    options.handle ?= ""

    tmpl = "{{> @icon}}"
    tmpl += "<span class='text'>not </span>" if options.handle is ""
    tmpl += "<span class='text'>on </span>{span.title{ #(title)}}"
    tmpl += "<span class='text'> as </span><span class='handle'>#{options.handle}</span>" if options.handle isnt ""

    return tmpl

class StaticHandleInput extends KDHitEnterInputView
  constructor:(options,data)->
    options.cssClass = 'profile-handle-customize'
    options.defaultValue = data.profile.handles?[options.service] or ''
    super options,data

class StaticAppsListItem extends KDListItemView
  partial:(data)->
    # log data
    "<div class='static-app'>
       #{data.title}
    </div>"

class StaticGroupsListItem extends KDListItemView
  partial:(data)->
    # log data
    "<div class='static-topic'>
       #{data.title}
    </div>"

class StaticTopicsListItem extends KDListItemView
  constructor:(options,data)->
     super options,data

     @titleView = new KDCustomHTMLView
       tagName : 'span'
       cssClass : 'static-topic-title'
       partial : @getData().title

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class='static-topic'>
       {{> @titleView}}
    </div>
    """

class StaticMembersListItem extends KDListItemView
  constructor:(options,data)->
    super options,data
    @avatarView = new AvatarView
      size    : {width: 30, height: 30}
      noTooltip : no
      click:->
    ,@getData()

    @setClass 'static-member'

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @avatarView}}
    """

  # partial:(data)->
  #   {profile} = data
  #   "<div class='static-member'>
  #      #{profile.nickname}
  #   </div>"
