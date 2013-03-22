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

    @profileHeaderView = new StaticProfileAboutHeaderView
      cssClass : 'about-header'
    ,@getData()

    if KD.whoami().getId() is @getData().getId()
      @editButton = new KDButtonView
        title : 'Edit this page'
        cssClass : 'about-edit-button clean-gray'
        callback : =>
          @$('.about-body').addClass 'hidden'
          @editView.show()
      @editView = new KDView
        cssClass : 'hidden about-edit'

      @editView.addSubView @editForm = new KDInputViewWithPreview
        defaultValue : Encoder.htmlDecode(about.content)
        cssClass : 'about-edit-input'

      @editView.addSubView @saveButton = new KDButtonView
        title : 'Save'
        cssClass : 'about-save-button clean-gray'
        loader          :
          diameter      : 12
        callback:=>
          @saveButton.showLoader()
          @getData().setAbout Encoder.XSSEncode(@editForm.getValue()), =>
            log arguments
            @editView.hide()
            @$('.about-body').removeClass 'hidden'
            @saveButton.hideLoader()
    else
      @editButton = new KDView
        cssClass : 'hidden'
      @editView = new KDView
        cssClass : 'hidden'

    @sideBarView = new StaticProfileAboutSidebarView
      cssClass : 'about-sidebar'
    , @getData()

  viewAppended:->
    super
    @setTemplate @pistachio()
    @template.update()

  pistachio:->
    """
    {{> @profileHeaderView}}
    {{> @sideBarView}}
    {{> @editButton}}
    {{> @editView}}
    <div class="about-body">
      <div class="has-markdown">
        <span class="data">
          #{@partial}
        </span>
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

    topicsController.hideLazyLoader()

    @profileUser.fetchFollowedTopics {},{},(err,topics)=>
      if topics
        @refreshActivities err, topics, 'topic'
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

    @profileUser.fetchFollowingWithRelationship {},{},(err, members)=>
      if members
        @refreshActivities err, members, 'member'
      else
        membersController.hideLazyLoader()
        log 'No members'

    @controllers['member'] = membersController
    @wrappers['member']    = @membersListWrapper


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
    """
    {{> @topicsListWrapper}}
    {{> @groupsListWrapper}}
    {{> @appsListWrapper}}
    {{> @membersListWrapper}}
    I AM SIDEBAR
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

    @profileUserUrlView = new CustomLinkView
      cssClass : 'url'
      href : "http://#{profile.nickname}.koding.com"
      title : "#{profile.nickname}.koding.com"
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

