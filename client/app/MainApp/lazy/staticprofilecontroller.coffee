class StaticProfileController extends KDController
  constructor:(options,data)->
    super options,data

    # reviving landing page as a whole

    profileLandingView = new KDView
      lazyDomId : 'profile-landing'

    profileLandingView.listenWindowResize()
    profileLandingView._windowDidResize = =>
      profileLandingView.setHeight window.innerHeight
      @profileContentView.setHeight window.innerHeight-profileTitleView.getHeight()

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

    @profileContentView = new KDListView
      lazyDomId : 'profile-content'
      itemClass : StaticBlogPostListItem
    , {}

    if @profileContentView.$().attr('data-count') > 0
      profileShowMoreView.show()

    # reviving content type selectors

    appManager = @getSingleton 'appManager'

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

    # reviving logo

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

    KD.remote.cacheable KD.config.profileEntryPoint, (err, user, name)=>

      unless err
        profileUser = user

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

          types = profileUser.profile.staticPage.showTypes or []

          profileStatusActivityItem.addSubView statusSwitch = new KDOnOffSwitch
            cssClass : 'profile-stream-switch'
            size : 'tiny'
            title     : 'Show'
            defaultValue : 'CStatusActivity' in types
            callback  : (state)=>
              profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CStatusActivity', =>

          profileBlogPostActivityItem.addSubView blogPostSwitch = new KDOnOffSwitch
            cssClass : 'profile-stream-switch'
            size : 'tiny'
            title     : 'Show'
            defaultValue : 'CBlogPostActivity' in types
            callback  : (state)=>
              profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CBlogPostActivity', =>

          profileCodeSnipActivityItem.addSubView codeSnipSwitch = new KDOnOffSwitch
            cssClass : 'profile-stream-switch'
            size : 'tiny'
            title     : 'Show'
            defaultValue : 'CCodeSnipActivity' in types
            callback  : (state)=>
              profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CCodeSnipActivity', =>

          profileDiscussionActivityItem.addSubView discussionSwitch = new KDOnOffSwitch
            cssClass : 'profile-stream-switch'
            size : 'tiny'
            title     : 'Show'
            defaultValue : 'CDiscussionActivity' in types
            callback  : (state)=>
              profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CDiscussionActivity', =>

          profileTutorialActivityItem.addSubView tutorialSwitch = new KDOnOffSwitch
            cssClass : 'profile-stream-switch'
            size : 'tiny'
            title     : 'Show'
            defaultValue : 'CTutorialActivity' in types
            callback  : (state)=>
              profileUser["#{if state then 'add' else 'remove'}StaticPageType"] 'CTutorialActivity', =>

    @on 'ShowMoreButtonClicked', =>
      @emit 'StaticProfileNavLinkClicked', 'CBlogPostActivity'
      # if profileUser
      #   log profileUser
      #   KD.remote.api.JBlogPost.some {originId : profileUser.getId()}, {limit:5,sort:{'meta.createdAt':-1}}, (err,blogs)=>
      #     if err
      #       log err
      #     else
      #       profileContentListController = new KDListViewController
      #         view : @profileContentView
      #         startWithLazyLoader : yes
      #       , blogs

      #       @profileContentView.$('.content-item').remove()

      #       @profileContentView.on 'ItemWasAdded', (instance, index)->
      #         instance.viewAppended()

      #       profileContentListController.instantiateListItems blogs

    @controller = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : ActivityListItemView

    @listWrapper = @controller.getView()
    @listWrapper.hide()
    @profileContentView.addSubView @listWrapper

    @on 'StaticProfileNavLinkClicked', (facets)=>
      if profileUser
        appManager.tell 'Activity', 'fetchActivity',
          originId : profileUser.getId()
          facets : [facets]
          bypass : yes
        , @bound "refreshActivities"


  refreshActivities:(err,activities)->
    @profileContentView.$('.content-item').remove()
    @listWrapper.show()

    @controller.removeAllItems()
    @controller.listActivities activities

class StaticNavLink extends KDView
  constructor:(options,data)->
    super options,data
    @unsetClass 'disabled'

  click :->
    @getDelegate().emit 'StaticProfileNavLinkClicked', @getDomId()