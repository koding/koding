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

  addEventListeners:->

    @on 'HomeLinkClicked', =>
      unless @staticListWrapper?
        @addStaticLogic()
      else
        @showWrapper @staticListWrapper

      @lockSidebar = no

      @utils.wait 250, =>
        @profileContentLinks.setClass 'links-hidden'
        @profileContentList.unsetClass 'has-links'

      # HERE is the place to implement custom profile splash screens, reveal.js and such

      @staticDefaultItem.show()
      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity', @staticListWrapper, @staticController, =>
        @showWrapper @staticListWrapper
        @staticDefaultItem.show()

    @on 'ActivityLinkClicked', (path)=>
      unless @activityListWrapper?
        @addActivityLogic()
      else
        @showWrapper @activityListWrapper

      @lockSidebar = yes

      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity', @activityListWrapper, @activityController, =>
        @showWrapper @activityListWrapper

      @utils.wait 250, =>
        @profileContentList.setClass 'has-links'
        @profileContentLinks.unsetClass 'links-hidden'

    @on 'AboutLinkClicked', (path)=>
      unless @aboutWrapper?
        @addAboutLogic =>
          @showWrapper @aboutWrapper
      else
        @showWrapper @aboutWrapper

      @lockSidebar = yes

      @profileContentList.unsetClass 'has-links'
      @profileContentLinks.setClass 'links-hidden'

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
      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity', @staticListWrapper, @staticController, =>
        @showWrapper @staticListWrapper

    @on 'StaticProfileNavLinkClicked', (facets,wrapper,controller,callback=->)=>
      @profileLoadingBar.setClass 'active'
      @profileLoaderView.show()
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
          , (err, activities)=>
            @refreshActivities err, activities, wrapper, controller
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
        @profilePersonalWrapperView.unsetClass 'collapsed'
        @profilePersonalWrapperView.setWidth 160
        @profileContentWrapperView.$().css marginLeft : "160px"

    @profilePersonalWrapperView.on 'mouseleave',(event)=>
      unless @lockSidebar
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
        @profilePersonalWrapperView.setClass 'slide-down'
        @profileContentWrapperView.setClass 'slide-down'
        @profileLogoView.setClass 'top'

        # @landingView.setClass 'profile-fading'
        # @utils.wait 1100, => @landingView.setClass 'profile-hidden'

        @getSingleton('lazyDomController').hideLandingPage()

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

  appendActivities:(err,activities, controller)->
    controller.listActivities activities
    controller.hideLazyLoader()

  refreshActivities:(err,activities,wrapperInstance,controllerInstance)->
    @profileShowMoreView.hide()

    # listWrapper = if isStatic then @staticListWrapper else @activityListWrapper
    # controller = if isStatic then @staticController else @activityController

    listWrapper = wrapperInstance
    controller = controllerInstance

    listWrapper.show()

    controller.removeAllItems()
    controller.listActivities activities

    controller.hideLazyLoader()
    @profileLoadingBar.unsetClass 'active'
    @profileLoaderView.hide()

  getAllowedTypes:(@profileUser)->
    allowedTypes = @profileUser.profile.staticPage?.showTypes or CONTENT_TYPES

  sanitizeStaticContent:(view)->
    view.$(".content-item > .has-markdown > span.data a").each (i,element)->
      $(element).attr target : '_blank'

  addActivityLogic:(callback=->)->
    log 'adding activity logic'
    @activityController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : ActivityListItemView
      viewOptions       :
        cssClass        : 'static-content activity-related'
      showHeader        : no

    @activityListWrapper = @activityController.getView()
    @profileContentView.addSubView @activityListWrapper

    @activityController.on 'LazyLoadThresholdReached', =>
      appManager.tell 'Activity', 'fetchActivity',
        originId  : @profileUser.getId()
        facets    : @currentFacets
        to        : @activityController.itemsOrdered.last.getData().meta.createdAt
        bypass    : yes
      , (err,activities)=>
        @appendActivities err,activities,@activityController

    callback()

  addAboutLogic:(callback=->)->
    log 'adding about logic'

    @profileLoadingBar.setClass 'active'
    @profileLoaderView.show()

    @aboutWrapper = yes

    @profileUser.fetchAbout (err,about)=>
      log arguments
      if err
        log err
      else
        unless about
          partial = '<div class="has-markdown nothing-here"><span class="data">Nothing here yet!</span></div>'
        else
          partial = "<div class='has-markdown'><span class='data'>#{about.html or about.content}</span></div>"

        log 'adding',partial

        @profileContentView.addSubView @aboutWrapper = new KDView
          partial : partial

        @profileLoadingBar.unsetClass 'active'
        @profileLoaderView.hide()

        callback()

  addStaticLogic:(callback=->)->
    log 'adding static logic'

    @staticController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticActivityListItemView
      viewOptions       :
        cssClass        : 'static-content'
      showHeader        : no

    @staticListWrapper = @staticController.getView()
    @profileContentView.addSubView @staticListWrapper

    @staticController.on 'LazyLoadThresholdReached', =>
      appManager.tell 'Activity', 'fetchActivity',
        originId  : @profileUser.getId()
        facets    : ['CBlogPostActivity']
        to        : @staticController.itemsOrdered.last.getData().meta.createdAt
        bypass    : yes
      , (err, activities)=>
       @appendActivities err, activities, @staticController

    callback()

  hideWrappers:->
    @profileContentView.$('.content-item.static').remove()

    @staticDefaultItem.hide()

    @profileShowMoreView.hide()
    @staticListWrapper?.hide()
    @activityListWrapper?.hide()
    @aboutWrapper?.hide()

  showWrapper:(wrapper)->
    @hideWrappers()
    wrapper.show()

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
    @getDelegate().emit 'StaticProfileNavLinkClicked', @getDomId()


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