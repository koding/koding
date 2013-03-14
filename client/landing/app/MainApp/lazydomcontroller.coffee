class LazyDomController extends KDController

  constructor:->
    super

    @groupViewsAdded   = no
    @profileViewsAdded = no

    @mainController = @getSingleton 'mainController'

    @mainController.on 'AppIsReady', =>
      if @userEnteredFromGroup()
        @addGroupViews()
      else if @userEnteredFromProfile()
        @addProfileViews()

      landingPageSideBar = new LandingPageSideBar

  userEnteredFromGroup:-> KD.config.groupEntryPoint?

  userEnteredFromProfile:-> KD.config.profileEntryPoint?

  addGroupViews:->

    return if @groupViewsAdded
    @groupViewsAdded = yes

    groupLandingView = new KDView
      lazyDomId : 'group-landing'

    groupLandingView.listenWindowResize()
    groupLandingView._windowDidResize = =>
      groupLandingView.setHeight window.innerHeight

    groupContentWrapperView = new KDView
      lazyDomId : 'group-content-wrapper'
      cssClass : 'slideable'

    new KDView
      lazyDomId : 'group-title'

    groupPersonalWrapperView = new KDView
      lazyDomId : 'group-personal-wrapper'
      cssClass  : 'slideable'
      click :(event)=>
        unless event.target.tagName is 'A'
          @mainController.loginScreen.unsetClass 'landed'

    groupLogoView = new KDView
      lazyDomId: 'group-koding-logo'
      click :=>
        groupPersonalWrapperView.setClass 'slide-down'
        groupContentWrapperView.setClass 'slide-down'
        groupLogoView.setClass 'top'

        groupLandingView.setClass 'group-fading'
        @utils.wait 1100, => groupLandingView.setClass 'group-hidden'

    groupLogoView.setY groupLandingView.getHeight()-42

    @utils.wait => groupLogoView.setClass 'animate'

  addProfileViews:->

    return if @profileViewsAdded
    @profileViewsAdded = yes

    profileLandingView = new KDView
      lazyDomId : 'profile-landing'

    profileLandingView.listenWindowResize()
    profileLandingView._windowDidResize = =>
      profileLandingView.setHeight window.innerHeight
      profileContentView.setHeight window.innerHeight-profileTitleView.getHeight()

    profileContentWrapperView = new KDView
      lazyDomId : 'profile-content-wrapper'
      cssClass : 'slideable'

    profileTitleView = new KDView
      lazyDomId : 'profile-title'

    profileShowMoreView = new KDView
      lazyDomId : 'profile-show-more-wrapper'
      cssClass : 'hidden'

    profileShowMoreButton = new KDButtonView
      lazyDomId : 'profile-show-more-button'
      title :'Show more'
      callback:=>
        @emit 'ShowMoreButtonClicked'
        profileShowMoreView.hide()
        profileShowMoreView.setHeight 0
        profileLandingView._windowDidResize()

    profileContentView = new KDListView
      lazyDomId : 'profile-content'
      itemClass : StaticBlogPostListItem
    , {}

    if profileContentView.$().attr('data-count') > 0
      profileShowMoreView.show()

    # profileSplitView = new SplitViewWithOlderSiblings
    #   lazyDomId : 'profile-splitview'
    #   parent : profileContentWrapperView

    profilePersonalWrapperView = new KDView
      lazyDomId : 'profile-personal-wrapper'
      cssClass : 'slideable'

    profileLogoView = new KDView
      lazyDomId: 'profile-koding-logo'
      click :=>
        profilePersonalWrapperView.setClass 'slide-down'
        profileContentWrapperView.setClass 'slide-down'
        profileLogoView.setClass 'top'

        profileLandingView.setClass 'profile-fading'
        @utils.wait 1100, => profileLandingView.setClass 'profile-hidden'

    profileLogoView.$().css
      top: profileLandingView.getHeight()-42

    profileUser = null
    @utils.wait => profileLogoView.setClass 'animate'

    KD.remote.cacheable profileLandingView.$().attr('data-profile'), (err, user, name)=>

      unless err
        profileUser = user

        if user.getId() is KD.whoami().getId()

          profileAdminCustomizeView = new KDView
            lazyDomId : 'profile-admin-customize'

          profileAdminCustomizeView.addSubView staticPageSettingsButton = new CustomLinkView
            title : 'Customize your Public Page'
            cssClass : 'static-page-settings-button clean-gray'
            click :=>
              modal = new StaticProfileSettingsModalView

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

    @on 'ShowMoreButtonClicked', =>
      if profileUser
        KD.remote.api.JBlogPost.some {originId : profileUser.getId()}, {limit:5,sort:{'meta.createdAt':-1}}, (err,blogs)=>
          if err
            log err

          else
            profileContentListController = new KDListViewController
              view : profileContentView
              startWithLazyLoader : yes
            , blogs

            profileContentView.$('.content-item').remove()

            profileContentView.on 'ItemWasAdded', (instance, index)->
              instance.viewAppended()

            profileContentListController.instantiateListItems blogs
