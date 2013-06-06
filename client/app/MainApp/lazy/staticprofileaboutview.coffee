class StaticProfileAboutView extends KDView
  constructor:(options,data)->
    super options,data

    @setClass 'profile-about-view'

    {about}   = @getOptions()
    {profile} = @getData()

    unless about
      @partial = 'Nothing here yet!'
    else
      @partial = Encoder.htmlDecode about.html or about.content

    @aboutView = new KDCustomHTMLView
      tagName : 'span'
      cssClass : 'data'
      partial : @partial

    # @profileHeaderView = new StaticProfileAboutHeaderView
    #   cssClass : 'about-header'
    # ,@getData()

    if KD.whoami().getId() is @getData().getId()
      @editButton = new KDButtonView
        title : 'Edit this page'
        cssClass : 'about-edit-button clean-gray'
        callback : =>
          @$('.about-body').addClass 'hidden'
          @editView.show()
          @editButton.hide()
      @editView = new KDView
        cssClass : 'hidden about-edit'

      @editView.addSubView @editForm = new KDInputViewWithPreview
        defaultValue : Encoder.htmlDecode(about.content)
        cssClass : 'about-edit-input'


      @editView.addSubView @saveButton = new KDButtonView
        title           : 'Save'
        cssClass        : 'about-save-button clean-gray'
        loader          :
          diameter      : 12
        callback:=>
          @saveButton.showLoader()
          @getData().setAbout Encoder.XSSEncode(@editForm.getValue()), (err,value)=>
            @editView.hide()
            @$('.about-body').removeClass 'hidden'
            @saveButton.hideLoader()
            @aboutView.updatePartial Encoder.htmlDecode value.html
            @editButton.show()

      @editView.addSubView @cancelButton = new KDButtonView
        title : 'Cancel'
        cssClass : 'about-cancel-button modal-cancel'
        callback :=>
          @editView.hide()
          @$('.about-body').removeClass 'hidden'
          @editButton.show()
    else
      @editButton = new KDView
        cssClass : 'hidden'
      @editView = new KDView
        cssClass : 'hidden'

    # @sideBarView = new StaticProfileAboutSidebarView
    #   cssClass : 'about-sidebar'
    # , @getData()

    if @getData().getId() is KD.whoami().getId()
      @profileView = new OwnProfileView
        cssClass : 'profilearea'
      , @getData()
    else
      @profileView = new ProfileView
        cssClass : 'profilearea'
      , @getData()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    # {{> @profileHeaderView}}
    # {{> @sideBarView}}
    """
    <div class="content-display-wrapper">
      <div class="content-display member">
         {{> @profileView}}
      </div>
    </div>
    {{> @editButton}}
    {{> @editView}}
    <div class="about-body">
      <div class="has-markdown">
        {{> @aboutView}}
      </div>
    </div>

    """


class StaticProfileAboutSidebarView extends KDView
  constructor:(options,data)->
    super options,data

    @controllers = {}
    @wrappers = {}
    @profileUser = @getData()

    topicsController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticTopicsListItem
      viewOptions       :
        cssClass        : 'static-content topic'
      showHeader        : no

    @topicsListWrapper = topicsController.getView()
    @topicsListWrapper.hide()

    topicsController.hideLazyLoader()

    @profileUser.fetchFollowedTopics {},{},(err,topics)=>
      if topics
        @refreshActivities err, topics, 'topic'
        @topicsHeaderView.show()
      else
        topicsController.hideLazyLoader()
        log 'No topics'

    @controllers['topic'] = topicsController
    @wrappers['topic']    = @topicsListWrapper

    groupsController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticGroupsListItem
      viewOptions       :
        cssClass        : 'static-content group'
      showHeader        : no

    @groupsListWrapper = groupsController.getView()

    @profileUser.fetchGroups (err,groups)=>
      if groups
        groupList = (item.group for item in groups)
        @refreshActivities err, groupList, 'group'
      else
        groupsController.hideLazyLoader()
        log 'No groups'

    @controllers['group'] = groupsController
    @wrappers['group']    = @groupsListWrapper

    appsController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticAppsListItem
      viewOptions       :
        cssClass        : 'static-content app'
      showHeader        : no

    @appsListWrapper = appsController.getView()

    KD.remote.api.JApp.some {originId : @profileUser.getId()},{},(err,apps)=>
      if apps?.length
        @refreshActivities err, apps, 'app'
      else
        appsController.hideLazyLoader()
        log 'No apps'

    @controllers['app'] = appsController
    @wrappers['app']    = @appsListWrapper

    membersController = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : StaticMembersListItem
      viewOptions       :
        cssClass        : 'static-content member'
      showHeader        : no

    @membersListWrapper = membersController.getView()
    @membersListWrapper.hide()

    @profileUser.fetchFollowingWithRelationship {},{},(err, members)=>
      if members
        @refreshActivities err, members, 'member'
        @membersHeaderView.show()
      else
        membersController.hideLazyLoader()
        log 'No members'

    @controllers['member'] = membersController
    @wrappers['member']    = @membersListWrapper

    {profile} = @getData()

    @topicsHeaderView = new KDView
      cssClass  : 'sidebar-header topics hidden'
      partial : "#{profile.firstName or profile.nickname}'s Topics"

    @membersHeaderView = new KDView
      cssClass  : 'sidebar-header members hidden'
      partial : "#{profile.firstName or profile.nickname}'s People"


  refreshActivities:(err,activities,type)->
    controller = @controllers[type]

    @wrappers[type].show()

    controller.removeAllItems()
    controller.listActivities activities

    controller.hideLazyLoader()


  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    # {{> @groupsListWrapper}}
    # {{> @appsListWrapper}}
    """
    {{> @membersHeaderView}}
    {{> @membersListWrapper}}

    {{> @topicsHeaderView}}
    {{> @topicsListWrapper}}

    """


class StaticProfileAboutHeaderView extends KDView
  constructor:(options,data)->
    super options,data

    {profile} = @getData()

    fallbackUri = "#{KD.apiUri}/images/defaultavatar/default.avatar.160.png"
    bgImg = "url(//gravatar.com/avatar/#{profile.hash}?size=#{160}&d=#{encodeURIComponent fallbackUri})"

    @$().css backgroundImage : bgImg

    @profileNicknameView = new KDView
      cssClass : 'nickname'
      partial : "@#{profile.nickname}"

    @profileNameView = new KDView
      cssClass : 'name'
      partial : [profile.firstName, profile.lastName].join ' '

    @profileLocationView = new KDView
      cssClass : 'location'
      partial : profile.locationTags?[0] or 'Earth'

    @profileAboutView = new KDView
      cssClass : 'about'
      partial : profile.about or ''

    {userSitesDomain} = KD.config

    @profileUserUrlView = new CustomLinkView
      cssClass : 'url'
      href : "http://#{profile.nickname}.#{userSitesDomain}"
      title : "#{profile.nickname}.#{userSitesDomain}"
      target : '_blank'

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    <div class="about-name">
      {{> @profileNameView}}
      {{> @profileLocationView}}
    </div>
    <div class="about-link">
      {{> @profileUserUrlView}}
    </div>
    <div class="about-about">
      {{> @profileAboutView}}
    </div>
    {{> @profileNicknameView}}
    """

