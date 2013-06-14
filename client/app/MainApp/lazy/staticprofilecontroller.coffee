class StaticProfileController extends KDController

  CONTENT_TYPES = [
    'CBlogPostActivity',
    'CStatusActivity','CCodeSnipActivity',
    'CDiscussionActivity', 'CTutorialActivity'
  ]

  constructorToPluralNameMap =
    'CStatusActivity'     : 'Status Updates'
    'CBlogPostActivity'   : 'Blog Posts'
    'CCodeSnipActivity'   : 'Code Snippets'
    'CDiscussionActivity' : 'Discussions'
    'CTutorialActivity'   : 'Tutorials'

  placeholderBioText      = 'Click here to enter a subtitle'


  constructor:(options,data)->
    super options,data

    @appManager = KD.getSingleton 'appManager'

    @navLinks     = {}
    @controllers  = {}
    @wrappers     = {}

    @profileUser  = null
    @registerSingleton 'staticProfileController', @, yes

    @reviveViewsOnPageLoad()
    @attachListeners()

    @mainController = @getSingleton 'mainController'
    @lazyDomController = @getSingleton('lazyDomController')

    # KD.remote.cacheable KD.config.entryPoint.slug, (err, user, name)=>
    # FIXME - we want to use cacheable, not a JAccount call, but names
    # are not working correctly

    KD.remote.api.JAccount.one
      "profile.nickname" : KD.config.entryPoint.slug
    , (err, user, name)=>
      if err then log err,user,name
      unless err
        @reviveViewsOnUserLoad user


  removeBackground:->
    @profileContentWrapperView.$().css backgroundImage : "none"
    @profileContentWrapperView.$().css backgroundColor : "#ffffff"

  setBackground:(type,val)->
    if type in ['defaultImage','customImage']
      @profileContentList.unsetClass 'vignette'
      @profileContentList.$().css backgroundColor : 'white'
      @utils.wait 200, =>
        @profileContentWrapperView.$().css backgroundImage : "url(#{val})"
        @utils.wait 200, =>
          @profileContentList.$().css backgroundColor : 'transparent'
    else
      @profileContentList.setClass 'vignette'
      @profileContentWrapperView.$().css backgroundImage : "none"
      @profileContentWrapperView.$().css backgroundColor : "#{val}"

  attachListeners:->

    @on 'CommentLinkReceivedClick', (view)=>
      if KD.whoami() instanceof KD.remote.api.JGuest
        new  KDNotificationView
          title : "Please log in to see this post and it's comments"

        @utils.wait 1000, =>
          @mainController.loginScreen.animateToForm 'login'
      else
        {entryPoint} = KD.config
        @lazyDomController.openPath "/Activity/#{view.getData().slug}", {entryPoint}


    @on 'CommentCountReceivedClick', (view)=>
      if KD.whoami() instanceof KD.remote.api.JGuest
        new  KDNotificationView
          title : "Please log in to see this post and it's comments"

        @utils.wait 1000, =>
          @mainController.loginScreen.animateToForm 'login'

      else
        {entryPoint} = KD.config
        @lazyDomController.openPath "/Activity/#{view.getData().slug}", {entryPoint}

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
          {entryPoint} = KD.config
          @lazyDomController.openPath "/Topics/#{view.getData().slug}", {entryPoint}


    @on 'HomeLinkClicked', (callback=->)=>

      @addLogic 'static'

      # HERE is the place to implement custom profile splash screens, reveal.js and such

      @staticDefaultItem.show()
      @displaySidebar no
      @profileContentWrapperView.unsetClass 'activity'

      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity', 'static', =>
        @profileContentWrapperView.unsetClass 'activity'
        unless @controllers['static'].itemsOrdered.length is 0
          @showWrapper @wrappers['static']

        @staticDefaultItem.show()
        callback()


    @on 'ActivityLinkClicked', (callback=->)=>
      if @controllers['activity']
        @displaySidebar yes
        @profileContentWrapperView.setClass 'activity'
      @addLogic 'activity'
      @emit 'StaticProfileNavLinkClicked', 'CStatusActivity', 'activity', =>
        @showWrapper @wrappers['activity']
        @displaySidebar yes
        @profileContentWrapperView.setClass 'activity'
        callback()


    @on 'AboutLinkClicked', (callback=->)=>
      @addLogic 'about', =>
        callback()
      @profileContentWrapperView.unsetClass 'activity'
      @displaySidebar no


    @on 'CustomizeLinkClicked',=>
      if (KD.whoami().getId() isnt @profileUser.getId()) or @customizeViewsAttached
        return

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
      unless @profileUser
        callback()
        return

      facets = [facets] if 'string' is typeof facets

      if @profileUser
        allowedTypes = @getAllowedTypes @profileUser

        blockedTypes = facets.reduce (acc, facet)->
          acc.push facet unless facet in allowedTypes
          return acc
        , []

        @emit 'DecorateStaticNavLinks', allowedTypes, facets.first
        if blockedTypes.length is 0 or type is 'static'
          @currentFacets = facets
          @appManager.tell 'Activity', 'fetchActivity',
            originId : @profileUser.getId()
            facets : facets
            bypass : yes
            limit  : 10
          , (err, activities=[])=>
            @refreshActivities err, activities, type
            callback()
        else
          @emit 'BlockedTypesRequested', blockedTypes
          @controllers[type].hideLazyLoader()
          callback()

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

      # reviving ADMIN views (inline edits, feeder checkboxes)

      @profileContentView.setClass 'allow-transitions'

      @profileConfigView = new KDView
        lazyDomId : 'profile-config'

      profileConfigWrapper = new KDView
        lazyDomId : 'back-wrapper'
        cssClass : 'allow-transitions'

      @profileTitleNameView = new KDView
        lazyDomId : 'profile-name'

      @profileTitleBioView = new KDView
        lazyDomId : 'profile-bio'


      handleLinks = {}

      handleLinks['twitter'] = new KDView
        tagName : 'a'
        lazyDomId : 'profile-handle-twitter'
        tooltip :
          title : 'Click here to change your Twitter handle'
        click:(event)->
          event.preventDefault()
          event.stopPropagation()
          handleInputs['twitter'].show()
          KD.utils.defer -> handleInputs['twitter'].setFocus()

      handleLinks['github'] = new KDView
        tagName : 'a'
        lazyDomId : 'profile-handle-github'
        tooltip :
          title : 'Click here to change your GitHub handle'
        click:(event)->
          event.preventDefault()
          event.stopPropagation()
          handleInputs['github'].show()
          KD.utils.defer -> handleInputs['github'].setFocus()

      handle.show() for name,handle of handleLinks

      handleInputs = {}

      for type in ['twitter','github']
        handleLinks[type].setClass 'edit'
        handleLinks[type].addSubView handleInputs[type] = new StaticHandleInput
          service     : type
          delegate    : @
          tooltip     :
            title     : "Enter your handle and hit enter to save."
            placement : 'right'
            direction : 'center'
            offset    :
              left    : 5
              top     : 2
          enableTabKey: yes
          attributes  :
            spellcheck: no
          cssClass    : 'hidden'
          blur        :->
            @hide()
          callback    :(value)->
            @getData().setHandle
              service : @getOptions().service
              value   : value
            , =>
              new KDNotificationView
                title : 'Your changes were saved.'
              @hide()
        , @profileUser

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
          enableTabKey  : yes
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

        unless @profileUser.profile.about or @profileUser.profile.staticPage?.about
          @profileTitleBioSpan.updatePartial placeholderBioText
          @profileTitleBioSpan.setClass 'dim'

        @profileTitleBioView.addSubView @profileTitleBioInput = new KDHitEnterInputView
          defaultValue  : Encoder.htmlDecode @profileUser.profile.staticPage?.about \
            or if @profileUser.profile.about
              "#{@profileUser.profile.about}"
            else placeholderBioText
          enableTabKey  : yes
          tooltip       :
            placement   : 'bottom'
            direction   : 'right'
            title       : 'Enter a subtitle and hit enter to save. Leaving this field empty will put your bio as default.'

          blur          : =>
            @profileTitleBioInput.hide()
            @profileTitleBioView.unsetClass 'edit'

          callback :(value)=>
            value = Encoder.htmlEncode value
            @profileUser.setStaticPageAbout Encoder.XSSEncode(value), =>
              @profileTitleBioView.unsetClass 'edit'
              if value is ''
                value = "#{@profileUser.profile.about or placeholderBioText}"
              else @profileTitleBioSpan.unsetClass 'dim'
              @profileTitleBioSpan.updatePartial value
              new KDNotificationView
                title   : 'Description updated.'

      @flipButtonFront   = new KDButtonView
          style           : 'flip-button editor-advanced-settings-menu'
          icon            : yes
          iconOnly        : yes
          iconClass       : "cog"
          callback        : (event)=>
            @profileContentWrapperView.setClass 'edit'

      @flipButtonBack  = new KDButtonView
          style           : 'flip-button editor-advanced-settings-menu'
          icon            : yes
          iconOnly        : yes
          iconClass       : "cog"
          callback        : (event)=>
            @profileContentWrapperView.unsetClass 'edit'

      @profileContentView.addSubView @flipButtonFront
      profileConfigWrapper.addSubView @flipButtonBack

      @profileConfigView.addSubView new StaticProfileCustomizeView
        delegate : @
      ,@profileUser


  reviveViewsOnPageLoad:->

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
      # @profileContentView.setHeight window.innerHeight-@profileTitleView.getHeight()


    groupKodingLogo = new KDView
      lazyDomId : 'landing-page-logo'
      tooltip   :
        title   : "Click here to go to Koding"
      click     : =>
        if KD.isLoggedIn()
          @lazyDomController.hideLandingPage()
        else
          @mainController.loginScreen.animateToForm 'login'

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
        if event.target.id is 'profile-personal-wrapper'
          @mainController.emit "landingSidebarClicked"

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

    @homeButton = new KDButtonView
      lazyDomId : 'profile-home-button'
      title     : 'Home'
      callback  : => @emit 'HomeLinkClicked'
    @activityButton = new KDButtonView
      title     : 'Activity'
      lazyDomId : 'profile-activity-button'
      callback  : => @emit 'ActivityLinkClicked'
    @aboutButton = new KDButtonView
      title     : 'About'
      lazyDomId : 'profile-about-button'
      callback  : => @emit 'AboutLinkClicked'

  reviveViewsOnUserLoad:(user)->

    @utils.defer => @emit 'HomeLinkClicked'

    @profileUser = user
    @emit 'DecorateStaticNavLinks', @getAllowedTypes(@profileUser), 'CBlogPostActivity'

    @profileTitleView.addSubView (new StaticUserButtonBar), null, yes

    unless user.getId() is KD.whoami().getId()
      @reviveVisitorViews() if KD.isLoggedIn()

    else
      @reviveAdminViews()


  appendActivities:(err,activities, type)->
    @controllers[type].listActivities activities
    @controllers[type].hideLazyLoader()


  refreshActivities:(err,activities,type)->
    unless err
      @profileShowMoreView.hide()

      controller = @controllers[type]
      @wrappers[type].show()

      controller.removeAllItems()
      controller.hideLazyLoader()

      controller.hideNoItemWidget()

      facetPlural = constructorToPluralNameMap[@currentFacets[0]] or 'activity'

      controller.getOptions().noItemFoundWidget.updatePartial \
        "So far, #{@profileUser.profile.firstName} has not posted any #{facetPlural}"

      if activities.length > 0
        controller.listActivities activities
      else
        unless type in ['static']
          controller.showNoItemWidget()
        #   @showWrapper @wrappers[type]
        # else
        #   @hideWrappers()
    else
      @controllers[type]?.hideLazyLoader()


  reviveVisitorViews:-> # put onboarding stuff here


  displaySidebar:(show=yes,delay=250)->
    @utils.wait delay, =>
      @profileContentList["#{if show then '' else 'un'}setClass"] 'has-links'
      @profileContentLinks["#{if show then 'un' else ''}setClass"] 'links-hidden'


  getAllowedTypes:(@profileUser)->
    allowedTypes = @profileUser.profile.staticPage?.showTypes or CONTENT_TYPES


  sanitizeStaticContent:(view)->
    view.$(".content-item > .has-markdown > span.data a").each (i,element)->
      $(element).attr target : '_blank'


  addLogic:(type,callback=->)->
      unless @controllers[type]?
        @addLogicForType type, =>
          @controllers[type]?.hideLazyLoader()
          callback()
      else
        @controllers[type]?.hideLazyLoader()
        @showWrapper @wrappers[type]
        callback()


  addLogicForType:(type,callback=->)->
    switch type
      when 'activity'
       @addActivityLogic callback

      when 'about'
       @addAboutLogic callback

      when 'static'
       @addStaticLogic callback


  addActivityLogic:(callback=->)->
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
      @appManager.tell 'Activity', 'fetchActivity',
        originId  : @profileUser.getId()
        facets    : @currentFacets
        to        : activityController.itemsOrdered.last.getData().meta.createdAt
        bypass    : yes
      , (err,activities)=>
        @appendActivities err,activities,'activity'

    @controllers['activity'] = activityController
    @wrappers['activity']    = activityListWrapper

    callback()


  addAboutLogic:(callback=->)->

    @wrappers['about'] = yes

    if @profileUser
      @profileUser.fetchAbout (err,about)=>
        if err
          log err
        else
          @profileContentView.addSubView aboutWrapper = new StaticProfileAboutView
            about : about or ''
          , @profileUser

          @wrappers['about'] = aboutWrapper
          @showWrapper aboutWrapper
          callback()


  addStaticLogic:(callback=->)->

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
      wrapper?.hide?()

  showWrapper:(wrapper)->
    @hideWrappers()
    wrapper.show()



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
    options.cssClass = "profile-handle-customize #{options.cssClass}"
    options.defaultValue = data.profile.handles?[options.service] or ''
    super options,data



# class StaticProfileSettingsView extends JView
#   constructor:(options,data)->
#     super options,data

#     @setClass 'settings-view ace-settings-view'

#     user = @getDelegate().profileUser

#     if user.profile.staticPage
#       {show} = user.profile.staticPage
#     else show = yes

#     @visibilityView = new KDOnOffSwitch
#       size                  : 'tiny'
#       defaultValue          : show
#       callback              : (value)=>
#           if show is yes
#             modal           = new KDModalView
#               cssClass      : 'disable-static-page-modal'
#               title         : 'Do you really want to disable your Public Page?'
#               content       : """
#                 <div class="modalformline">
#                   <p>Disabling this feature will disable other people
#                   from publicly viewing your profile. You will still be
#                   able to access the page yourself.</p>
#                   <p>Do you want to continue?</p>
#                 </div>
#                 """
#               buttons       :
#                 "Disable the Public Page" :
#                   cssClass  : 'modal-clean-red'
#                   callback  : =>
#                     modal.destroy()
#                     user.setStaticPageVisibility no, (err,res)=>
#                       if err then log err
#                 Cancel      :
#                   cssClass  : 'modal-cancel'
#                   callback  : =>
#                     @visibilityView.setValue off
#                     modal.destroy()
#           else
#             user.setStaticPageVisibility yes, (err,res)=>
#               if err then log err

#   pistachio:->
#     """
#     <p>Make this page Public   {{> @visibilityView}}</p>
#     """


#   click:(event)->

#     event.preventDefault()
#     event.stopPropagation()
#     return no