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
    @lockSidebar  = no

    @registerSingleton 'staticProfileController', @, no

    @reviveViewsOnPageLoad()
    @addEventListeners()

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
          @showWrapper @wrappers[type]
          @controllers[type]?.hideLazyLoader()
      else
        @controllers[type]?.hideLazyLoader()
        @showWrapper @wrappers[type]

      @lockSidebar = lockSidebar
      @displaySidebar displaySidebar

  displaySidebar:(show=yes,delay=250)->
    @utils.wait delay, =>
      @profileContentList["#{if show then '' else 'un'}setClass"] 'has-links'
      @profileContentLinks["#{if show then 'un' else ''}setClass"] 'links-hidden'

  addEventListeners:->

    @on 'GroupsLinkClicked', =>
      @addLogic 'group', yes, no

    @on 'TopicLinkClicked', =>
      @addLogic 'topic', yes, no

    @on 'PeopleLinkClicked', =>
      @addLogic 'member', yes, no

    @on 'AppsLinkClicked', =>
      @addLogic 'app', yes, no

    @on 'HomeLinkClicked', =>
      @addLogic 'static', no, no

      # HERE is the place to implement custom profile splash screens, reveal.js and such

      @staticDefaultItem.show()
      @showLoadingBar()
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
      return if @customizeViewsAttached or KD.whoami().getId() isnt @profileUser.getId()
      @customizeViewsAttached = yes

      @avatarAreaIconMenu.emit 'CustomizeLinkClicked'

      # reviving customization
      types = @getAllowedTypes @profileUser

      for type in CONTENT_TYPES
        @navLinks[type].addSubView new StaticNavCheckBox
          activityType : type
          defaultValue : type in types
          delegate     : @
        , @profileUser

      profileTitleNameView = new KDView
        lazyDomId : 'profile-name'
        cssClass : 'edit'

      profileTitleNameView.addSubView profileTitleNameInput = new KDHitEnterInputView
        defaultValue : Encoder.htmlDecode @profileUser.profile.staticPage?.title or ''
        tooltip :
          title : 'Enter your page title and hit enter to save. Leaving this field empty will put your full name as default title.'
        callback :(value)=>
          value = Encoder.htmlEncode value
          @profileUser.setStaticPageTitle Encoder.XSSEncode(value), =>
            # profileTitleNameView.unsetClass 'edit'
            # profileTitleNameView.updatePartial value
            new KDNotificationView
              title : 'Title updated.'

      profileTitleBioView = new KDView
        lazyDomId : 'profile-bio'
        cssClass : 'edit'

      profileTitleBioView.addSubView profileTitleBioInput = new KDHitEnterInputView
        defaultValue : Encoder.htmlDecode @profileUser.profile.staticPage?.about or ''
        tooltip :
          title : 'Enter your page description and hit enter to save. Leaving this field empty will put your bio as default description.'
        callback :(value)=>
          value = Encoder.htmlEncode value
          @profileUser.setStaticPageAbout Encoder.XSSEncode(value), =>
            # profileTitleBioView.unsetClass 'edit'
            # profileTitleBioView.updatePartial value
            new KDNotificationView
              title : 'Description updated.'


    @on 'ShowMoreButtonClicked', =>
      @addStaticLogic()
      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity', 'static', =>
        @showWrapper @staticListWrapper


    @on 'StaticProfileNavLinkClicked', (facets,type,callback=->)=>

      @showLoadingBar() #unless type in ['activity','static']

      facets = [facets] if 'string' is typeof facets

      if @profileUser
        allowedTypes = @getAllowedTypes @profileUser

        blockedTypes = facets.reduce (acc, facet)->
          acc.push facet unless facet in allowedTypes
          return acc
        , []

        @emit 'DecorateStaticNavLinks', allowedTypes

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
      @repositionLogoView()

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
      bind : 'mouseenter mouseleave'

    #
    # allow for sidebar lock here!
    # resize avatar to center or something
    #

    @profilePersonalWrapperView.on 'mouseenter',(event)=>
        @getSingleton('mainController').loginScreen.unsetClass 'sidebar-collapsed'
        @profilePersonalWrapperView.unsetClass 'collapsed'
        @profilePersonalWrapperView.setWidth 160
        @profileContentWrapperView.$().css marginLeft : "160px"

    @profilePersonalWrapperView.on 'mouseleave',(event)=>
      unless @lockSidebar
        @getSingleton('mainController').loginScreen.setClass 'sidebar-collapsed'
        @profilePersonalWrapperView.setClass 'collapsed'
        @profilePersonalWrapperView.setWidth 50
        @profileContentWrapperView.$().css marginLeft : "50px"

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

    @emit 'DecorateStaticNavLinks', allowedTypes

    # reviving loading bar
    @profileLoadingBar = new KDView
      lazyDomId : 'profile-loading-bar'
      partial   : 'Loading'
    @profileLoadingBar.addSubView @profileLoaderView = new KDLoaderView
      size          :
        width       : 16
        height      : 16
      loaderOptions :
        color       : '#ff9200'
    @profileLoaderView.hide()

    # reviving logo for the slideup animation
    @profileLogoView = new KDView
      lazyDomId: 'profile-koding-logo'
      click :=>
        unless KD.whoami() instanceof KD.remote.api.JGuest
          @profilePersonalWrapperView.setClass 'slide-down'
          @profileContentWrapperView.setClass 'slide-down'
          @profileLogoView.setClass 'top'

          # @landingView.setClass 'profile-fading'
          # @utils.wait 1100, => @landingView.setClass 'profile-hidden'

          @getSingleton('lazyDomController').hideLandingPage()
        else
          @getSingleton('mainController').loginScreen.animateToForm 'register'

    @repositionLogoView()
    # @addStaticLogic()

    console.timeEnd 'reviving page elements on pageload.'

  reviveViewsOnUserLoad:(user)->

    console.time 'reviving page elements on userload.'

    @utils.wait 500, => @profileLogoView.setClass 'animate'

    @profileUser = user
    @emit 'DecorateStaticNavLinks', @getAllowedTypes @profileUser

    @avatarAreaIconMenu = new StaticAvatarAreaIconMenu
      lazyDomId    : 'profile-buttons'
      delegate     : @
    , @profileUser

    @avatarAreaIconMenu.$('.static-profile-button').remove()

    if user.getId() is KD.whoami().getId()

      # reviving admin stuff

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

    console.timeEnd 'reviving page elements on userload.'
    console.timeEnd 'StaticProfileController'


  repositionLogoView:->
    @profileLogoView.$().css
      top: @landingView.getHeight()-42

  appendActivities:(err,activities, type)->
    @controllers[type].listActivities activities
    @controllers[type].hideLazyLoader()

  refreshActivities:(err,activities,type)->
    @profileShowMoreView.hide()

    controller = @controllers[type]
    @wrappers[type].show()

    controller.removeAllItems()
    controller.listActivities activities

    controller.hideLazyLoader()

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
          callback()


  addTopicLogic:(callback=->)->
    log 'adding topics logic'

    topicsController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticTopicsListItem
      viewOptions       :
        cssClass        : 'static-content topic'
      showHeader        : no

    topicsListWrapper = topicsController.getView()
    @profileContentView.addSubView topicsListWrapper

    topicsController.hideLazyLoader()

    @showLoadingBar()
    @profileUser.fetchFollowedTopics {},{},(err,topics)=>
      if topics
        @refreshActivities err, topics, 'topic'
      else
        topicsController.hideLazyLoader()
        @hideLoadingBar()
        log 'No topics'

    @controllers['topic'] = topicsController
    @wrappers['topic']    = topicsListWrapper

    callback()


  addGroupsLogic:(callback=->)->
    log 'adding groups logic'

    groupsController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticGroupsListItem
      viewOptions       :
        cssClass        : 'static-content group'
      showHeader        : no

    groupsListWrapper = groupsController.getView()
    @profileContentView.addSubView groupsListWrapper

    @showLoadingBar()
    @profileUser.fetchGroups (err,groups)=>
      if groups
        groupList = (item.group for item in groups)
        @refreshActivities err, groupList, 'group'
      else
        groupsController.hideLazyLoader()
        @hideLoadingBar()
        log 'No groups'

    @controllers['group'] = groupsController
    @wrappers['group']    = groupsListWrapper

    callback()


  addAppsLogic:(callback=->)->
    log 'adding apps logic'

    appsController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticAppsListItem
      viewOptions       :
        cssClass        : 'static-content app'
      showHeader        : no

    appsListWrapper = appsController.getView()
    @profileContentView.addSubView appsListWrapper

    @showLoadingBar()
    KD.remote.api.JApp.some {originId : @profileUser.getId()},{},(err,apps)=>
      if apps?.length
        @refreshActivities err, apps, 'app'
      else
        appsController.hideLazyLoader()
        @hideLoadingBar()
        log 'No apps'

    @controllers['app'] = appsController
    @wrappers['app']    = appsListWrapper

    callback()


  addMembersLogic:(callback=->)->
    log 'adding members logic'

    membersController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticMembersListItem
      viewOptions       :
        cssClass        : 'static-content member'
      showHeader        : no

    membersListWrapper = membersController.getView()
    @profileContentView.addSubView membersListWrapper

    @showLoadingBar()
    @profileUser.fetchFollowingWithRelationship {},{},(err, members)=>
      if members
        @refreshActivities err, members, 'member'
      else
        membersController.hideLazyLoader()
        @hideLoadingBar()
        log 'No members'

    @controllers['member'] = membersController
    @wrappers['member']    = membersListWrapper

    callback()


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
    @showHomeLink()
    wrapper.show()

  setHomeLink:(view)->
    @homeLink = view
    view.setClass 'invisible'

  showHomeLink:->
    @homeLink.unsetClass 'invisible'



class StaticNavLink extends KDView
  constructor:(options,data)->
    super options,data
    @unsetClass 'disabled'

    @getDelegate().on 'DecorateStaticNavLinks',(allowedTypes)=>
      @decorate allowedTypes

  decorate:(allowedTypes)->
      if @getDomId() in allowedTypes
        @unsetClass 'blocked'
      else
        @setClass 'blocked'

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
      @getDelegate().emit 'DecorateStaticNavLinks', @getDelegate().getAllowedTypes @getData()


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
  partial:(data)->
    log data
    "<div class='static-topic'>
       #{data.title}
       #{data.body}
       #{data.counts.followers}
       #{data.counts.post}
    </div>"

class StaticMembersListItem extends KDListItemView
  partial:(data)->
    {profile} = data
    "<div class='static-member'>
       #{profile.nickname}
    </div>"
