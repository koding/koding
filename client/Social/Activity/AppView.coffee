class ActivityAppView extends KDScrollView


  headerHeight = 0

  {entryPoint, permissions, roles} = KD.config

  isGroup        = -> entryPoint?.type is 'group'
  isKoding       = -> entryPoint?.slug is 'koding'
  isMember       = -> 'member' in roles
  canListMembers = -> 'list members' in permissions
  isPrivateGroup = -> not isKoding() and isGroup()


  constructor:(options = {}, data)->

    options.cssClass   = 'content-page activity'
    options.domId      = 'content-page-activity'

    super options, data

    {entryPoint}      = KD.config
    {
      windowController
      widgetController
      mainController
      appStorageController
    } = KD.singletons

    @appStorage = appStorageController.storage 'Activity', '1.0.1'
    @appStorage.setValue 'liveUpdates', off

    # main components
    @sidebar           = new KDCustomScrollView tagName : 'aside'
    @feedWrapper       = new ActivityListContainer
    @inputWidget       = new ActivityInputWidget
    @topWidgetWrapper  = new KDCustomHTMLView
    @leftWidgetWrapper = new KDCustomHTMLView
    @groupCoverView    = new FeedCoverPhotoView

    widgetController.showWidgets [
      { view: @topWidgetWrapper,  key: 'ActivityTop'  }
      { view: @leftWidgetWrapper, key: 'ActivityLeft' }
    ]

    @sidebar.once 'viewAppended', =>
      @sidebar.addSubView @leftWidgetWrapper

    @inputWidget.on 'ActivitySubmitted', @bound 'activitySubmitted'
    mainController.on 'AccountChanged', @bound "decorate"
    mainController.on 'JoinedGroup', => @inputWidget.show()

    @feedWrapper.ready =>
      @activityHeader  = @feedWrapper.controller.activityHeader
      {@filterWarning} = @feedWrapper
      {feedFilterNav}  = @activityHeader
      feedFilterNav.unsetClass 'multiple-choice on-off'

    @once 'viewAppended', =>


  viewAppended: ->

    JView::viewAppended.call this

    @decorate()
    @setLazyLoader 200

    aa = (v)=> @sidebar.wrapper.addSubView v

    # temp items
    aa new DummyTopics
    aa new DummyTopics
    aa new DummyUsers
    aa new DummyUsers
    aa new DummyUsers



  pistachio:->
    """
    {{> @groupCoverView}}
    {{> @sidebar}}
    <main>
      {{> @inputWidget}}
      {{> @feedWrapper}}
      {{> @topWidgetWrapper}}
    </main>
    """


  activitySubmitted:->

    appTop   = @getElement().offsetTop
    listTop  = @feedWrapper.listWrapper.getElement().offsetTop
    duration = @feedWrapper.pinnedListWrapper.getHeight() * .3
    $('html, body').animate {scrollTop: appTop + listTop + 10}, {duration}


  decorate:->

    {entryPoint, roles} = KD.config

    @unsetClass 'guest'
    @setClass 'guest'     unless isMember()
    @setClass 'loggedin'  if KD.isLoggedIn()

    unless isMember()
    then @inputWidget.hide()
    else @inputWidget.show()

    @_windowDidResize()


  setTopicTag: (slug) ->

    return  unless slug

    KD.remote.api.JTag.one {slug}, null, (err, tag) =>
      @inputWidget.input.setDefaultTokens tags: [tag]


  unsetTopicTag: -> @inputWidget.input.setDefaultTokens tags: []
