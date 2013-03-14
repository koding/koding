class StaticProfileController extends KDController
  constructor:(options,data)->
    super options,data

    appManager = @getSingleton 'appManager'

    @controller = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticActivityListItemView
      viewOptions       :
        cssClass        : 'static-content'
      showHeader        : no

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
    profileUser = null
    allowedTypes = ['CBlogPostActivity']
    blockedTypes = []

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
      cssClass : 'hidden'

    profileShowMoreButton = new KDButtonView
      lazyDomId : 'profile-show-more-button'
      title :'Show more'
      callback:=>
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
      cssClass : 'slideable'

    profilePersonalWrapperView = new KDView
      lazyDomId : 'profile-personal-wrapper'
      cssClass : 'slideable'

    # reviving feed type selectors that will activate feed facets
    profileStatusActivityItem = new StaticNavLink
      delegate : @
      lazyDomId : 'CStatusActivity'

    profileBlogPostActivityItem = new StaticNavLink
      delegate : @
      lazyDomId : 'CBlogPostActivity'

    profileCodeSnipActivityItem = new StaticNavLink
      delegate : @
      lazyDomId : 'CCodeSnipActivity'

    profileDiscussionActivityItem = new StaticNavLink
      delegate : @
      lazyDomId : 'CDiscussionActivity'

    profileTutorialActivityItem = new StaticNavLink
      delegate : @
      lazyDomId : 'CTutorialActivity'

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

    KD.remote.cacheable KD.config.profileEntryPoint, (err, user, name)=>

      unless err
        profileUser = user
        @emit 'DecorateStaticNavLinks', @getAllowedTypes profileUser

        if user.getId() is KD.whoami().getId()

          # reviving admin stuff

          profileAdminCustomizeView = new KDView
            lazyDomId : 'profile-admin-customize'

          profileAdminCustomizeView.addSubView staticPageSettingsButton = new CustomLinkView
            title : 'Customize your Public Page'
            cssClass : 'static-page-settings-button clean-gray'
            click :=>
              # modal = new StaticProfileSettingsModalView
              @emit 'CustomizeLinkClicked'
          profileAdminCustomizeView.show()

          profileAdminMessageView = new KDView
            lazyDomId : 'profile-admin-message'

          showPage = user.profile.staticPage?.show

          profileAdminMessageView.addSubView disableLink = new CustomLinkView
            title : "#{if showPage is yes then 'Disable' else 'Enable'} this Public Page"
            cssClass : 'message-disable'
            click : (event)=>
              event?.stopPropagation()
              event?.preventDefault()

              if user.profile.staticPage?.show is yes
                modal =  new KDModalView
                  cssClass : 'disable-static-page-modal'
                  title : 'Do you really want to disable your Public Page?'
                  content : """
                    <div class="modalformline">
                      <p>Disabling this feature will disable other people
                      from publicly viewing your profile. You will still be
                      able to access the page yourself.</p>
                      <p>Do you want to continue?</p>
                    </div>
                    """
                  buttons :
                    "Disable the Public Page" :
                      cssClass : 'modal-clean-red'
                      callback :=>
                        modal.destroy()
                        user.setStaticPageVisibility no, (err,res)=>
                          if err then log err
                          disableLink.updatePartial 'Enable this Public Page'
                    Cancel :
                      cssClass : 'modal-cancel'
                      callback :=>
                        modal.destroy()
              else
                user.setStaticPageVisibility yes, (err,res)=>
                  if err then log err
                  disableLink.updatePartial 'Disable this Public Page'


    @on 'CustomizeLinkClicked',=>
      # reviving customization

      types = @getAllowedTypes profileUser

      profileStatusActivityItem.addSubView statusSwitch = new KDOnOffSwitch
        cssClass : 'profile-stream-switch'
        size : 'tiny'
        title     : 'Show'
        defaultValue : 'CStatusActivity' in types
        callback  : (state)=>
          profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CStatusActivity', =>
            @emit 'DecorateStaticNavLinks', @getAllowedTypes profileUser

      profileBlogPostActivityItem.addSubView blogPostSwitch = new KDOnOffSwitch
        cssClass : 'profile-stream-switch'
        size : 'tiny'
        title     : 'Show'
        defaultValue : 'CBlogPostActivity' in types
        callback  : (state)=>
          profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CBlogPostActivity', =>
            @emit 'DecorateStaticNavLinks', @getAllowedTypes profileUser

      profileCodeSnipActivityItem.addSubView codeSnipSwitch = new KDOnOffSwitch
        cssClass : 'profile-stream-switch'
        size : 'tiny'
        title     : 'Show'
        defaultValue : 'CCodeSnipActivity' in types
        callback  : (state)=>
          profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CCodeSnipActivity', =>
            @emit 'DecorateStaticNavLinks', @getAllowedTypes profileUser

      profileDiscussionActivityItem.addSubView discussionSwitch = new KDOnOffSwitch
        cssClass : 'profile-stream-switch'
        size : 'tiny'
        title     : 'Show'
        defaultValue : 'CDiscussionActivity' in types
        callback  : (state)=>
          profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CDiscussionActivity', =>
            @emit 'DecorateStaticNavLinks', @getAllowedTypes profileUser

      profileTutorialActivityItem.addSubView tutorialSwitch = new KDOnOffSwitch
        cssClass : 'profile-stream-switch'
        size : 'tiny'
        title     : 'Show'
        defaultValue : 'CTutorialActivity' in types
        callback  : (state)=>
          profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CTutorialActivity', =>
            @emit 'DecorateStaticNavLinks', @getAllowedTypes profileUser

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
          appManager.tell 'Activity', 'fetchActivity',
            originId : profileUser.getId()
            facets : facets
            bypass : yes
          , @bound "refreshActivities"
        else @emit 'BlockedTypesRequested', blockedTypes

  repositionLogoView:->
    @profileLogoView.$().css
      top: @profileLandingView.getHeight()-42

  refreshActivities:(err,activities)->
    @profileContentView.$('.content-item').remove()
    @profileShowMoreView.hide()
    @listWrapper.show()

    @controller.removeAllItems()
    @controller.listActivities activities

  getAllowedTypes:(profileUser)->
      allowedTypes = profileUser.profile.staticPage?.showTypes or [
        'CBlogPostActivity','CStatusActivity','CCodeSnipActivity',
        'CDiscussionActivity', 'CTutorialActivity'
      ]


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