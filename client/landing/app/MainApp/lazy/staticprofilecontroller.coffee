class StaticProfileController extends KDController

  CONTENT_TYPES = [
    'CBlogPostActivity','CStatusActivity','CCodeSnipActivity',
    'CDiscussionActivity', 'CTutorialActivity'
  ]

  constructor:(options,data)->
    super options,data

    appManager = @getSingleton 'appManager'

    @controller = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : ActivityListItemView
      viewOptions       :
        cssClass        : 'static-content activity-related'
      showHeader        : no

    @navLinks     = {}

    # reviving the content view. this encapsulates the listitem feed after
    # user input (type selection, more-button)
    @profileContentView = new KDListView
      lazyDomId : 'profile-content'
      itemClass : StaticActivityListItemView
    , {}

    @listWrapper = @controller.getView()
    @listWrapper.hide()
    @profileContentView.addSubView @listWrapper

    # this is the JAccount object of the static profile
    profileUser   = null
    allowedTypes  = ['CBlogPostActivity']
    blockedTypes  = []
    currentFacets = []

    # reviving the landing page. this is needed to handle window
    # resize events for the view and subviews
    @profileLandingView = new KDView
      lazyDomId : 'profile-landing'

    @profileLandingView.listenWindowResize()
    @profileLandingView._windowDidResize = =>
      @profileLandingView.setHeight window.innerHeight
      @profileContentView.setHeight window.innerHeight-profileTitleView.getHeight()
      @repositionLogoView()

    profileTitleView = new KDView
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
        @profileLandingView._windowDidResize()

    if @profileContentView.$().attr('data-count') > 0
      @profileShowMoreView.show()

    # reviving wrapper views for resize/slide animations as well as
    # adding administrative views
    profileContentWrapperView = new KDView
      lazyDomId : 'profile-content-wrapper'
      cssClass  : 'slideable'

    profilePersonalWrapperView = new KDView
      lazyDomId : 'profile-personal-wrapper'
      cssClass  : 'slideable'
      bind : 'mouseenter mouseleave'

    #
    # allow for sidebar lock here!
    # resize avatar to center or something
    #

    profilePersonalWrapperView.on 'mouseenter',=>
      profilePersonalWrapperView.setWidth 160
      profileContentWrapperView.$().css marginLeft : "160px"

    profilePersonalWrapperView.on 'mouseleave',=>
      profilePersonalWrapperView.setWidth 50
      profileContentWrapperView.$().css marginLeft : "50px"

    # reviving feed type selectors that will activate feed facets

    for type in CONTENT_TYPES
      @navLinks[type] = new StaticNavLink
        delegate  : @
        lazyDomId : type

    @emit 'DecorateStaticNavLinks', allowedTypes

    # reviving logo for the slideup animation
    @profileLogoView = new KDView
      lazyDomId: 'profile-koding-logo'
      click :=>
        profilePersonalWrapperView.setClass 'slide-down'
        profileContentWrapperView.setClass 'slide-down'
        @profileLogoView.setClass 'top'

        @profileLandingView.setClass 'profile-fading'
        @utils.wait 1100, => @profileLandingView.setClass 'profile-hidden'

    @repositionLogoView()

    @utils.wait => @profileLogoView.setClass 'animate'


    # KD.remote.cacheable KD.config.profileEntryPoint, (err, user, name)=>


    KD.remote.api.JAccount.one
      "profile.nickname" : KD.config.profileEntryPoint
    , (err, user, name)=>
      if err then log err,user,name
      unless err

        profileUser = user
        @emit 'DecorateStaticNavLinks', @getAllowedTypes profileUser

        @avatarAreaIconMenu = new StaticAvatarAreaIconMenu
          lazyDomId    : 'profile-buttons'
          delegate     : @
        , profileUser

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


    @on 'CustomizeLinkClicked',=>
      return if @customizeViewsAttached or KD.whoami().getId() isnt profileUser.getId()
      @customizeViewsAttached = yes

      @avatarAreaIconMenu.emit 'CustomizeLinkClicked'

      # reviving customization

      types = @getAllowedTypes profileUser

      for type in CONTENT_TYPES
        @navLinks[type].addSubView new StaticNavCheckBox
          activityType : type
          defaultValue : type in types
          delegate     : @
        , profileUser

    @on 'ShowMoreButtonClicked', =>
      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity'

    @on 'StaticProfileNavLinkClicked', (facets)=>
      facets = [facets] if 'string' is typeof facets

      if profileUser
        allowedTypes = @getAllowedTypes profileUser

        blockedTypes = facets.reduce (acc, facet)->
          acc.push facet unless facet in allowedTypes
          return acc
        , []

        @emit 'DecorateStaticNavLinks', allowedTypes

        if blockedTypes.length is 0
          currentFacets = facets
          appManager.tell 'Activity', 'fetchActivity',
            originId : profileUser.getId()
            facets : facets
            bypass : yes
          , @bound "refreshActivities"
        else @emit 'BlockedTypesRequested', blockedTypes

    @controller.on 'LazyLoadThresholdReached', =>
      appManager.tell 'Activity', 'fetchActivity',
        originId  : profileUser.getId()
        facets    : currentFacets
        to        : @controller.itemsOrdered.last.getData().meta.createdAt
        bypass    : yes
      , @bound "appendActivities"

  repositionLogoView:->
    @profileLogoView.$().css
      top: @profileLandingView.getHeight()-42

  appendActivities:(err,activities)->
    @controller.listActivities activities
    @controller.hideLazyLoader()


  refreshActivities:(err,activities)->
    @profileContentView.$('.content-item').remove()
    @profileShowMoreView.hide()
    @listWrapper.show()

    @controller.removeAllItems()
    @controller.listActivities activities

    @controller.hideLazyLoader()

  getAllowedTypes:(profileUser)->
      allowedTypes = profileUser.profile.staticPage?.showTypes or CONTENT_TYPES


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