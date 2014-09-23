class ActivityAppView extends KDScrollView

  JView.mixin @prototype

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
      mainController
      appStorageController
    } = KD.singletons

    @appStorage = appStorageController.storage 'Activity', '1.0.1'
    @appStorage.setValue 'liveUpdates', off

    # main components
    @feedWrapper       = new ActivityListContainer
    @inputWidget       = new ActivityInputWidget
    @referalBox        = new ReferalBox
    @topWidgetWrapper  = new KDCustomHTMLView
    @leftWidgetWrapper = new KDCustomHTMLView
    @groupListBox      = new UserGroupList
    @topicsBox         = new ActiveTopics
    @usersBox          = new ActiveUsers

    # TODO : if not on private group DO NOT create those ~EA
    # group components
    @groupCoverView   = new FeedCoverPhotoView
    @groupDescription = new GroupDescription
    @groupMembers     = new GroupMembers

    mainController.ready =>
      {widgetController} = KD.singletons
      widgetController.showWidgets [
        { view: @topWidgetWrapper,  key: 'ActivityTop'  }
        { view: @leftWidgetWrapper, key: 'ActivityLeft' }
      ]

    mainController.on 'AccountChanged', @bound "decorate"
    mainController.on 'JoinedGroup', => @inputWidget.show()
    @feedWrapper.ready =>
      @activityHeader  = @feedWrapper.controller.activityHeader
      {@filterWarning} = @feedWrapper
      {feedFilterNav}  = @activityHeader
      feedFilterNav.unsetClass 'multiple-choice on-off'


  viewAppended: ->

    appendAside = (view)=> @addSubView view, 'aside'

    JView::viewAppended.call this

    @decorate()
    @setLazyLoader 200

    appendAside @referalBox       if KD.isLoggedIn() and not isPrivateGroup()
    appendAside @groupDescription if isPrivateGroup()
    appendAside @groupMembers     if isPrivateGroup() and canListMembers()
    appendAside @groupListBox     if isKoding()
    appendAside @topicsBox
    appendAside @usersBox         if canListMembers()


  pistachio:->
    """
    {{> @groupCoverView}}
    <main>
      {{> @inputWidget}}
      {{> @feedWrapper}}
      {{> @topWidgetWrapper}}
    </main>
    <aside>
      {{> @leftWidgetWrapper}}
    </aside>
    """


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


  # ticker: if we ever need to put it back it's here. at least for a while.- SY
    # @tickerBox        = new ActivityTicker

    # calculateTopOffset = =>
    #   KD.utils.wait 3000, =>
    #     @topOffset = @tickerBox.$().position().top


    # @tickerBox.once 'viewAppended', =>
    #   calculateTopOffset()
    #   windowController.on 'ScrollHappened', =>
    #     # sanity check
    #     calculateTopOffset()  if @topOffset < 200
    #     if document.documentElement.scrollTop > @topOffset
    #     then @tickerBox.setClass 'fixed'
    #     else @tickerBox.unsetClass 'fixed'

    # @groupListBox.on 'TopOffsetShouldBeFixed', calculateTopOffset


    # @sideBlock.addSubView @tickerBox
