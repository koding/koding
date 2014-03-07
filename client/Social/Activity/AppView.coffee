class ActivityAppView extends KDScrollView


  headerHeight = 0


  constructor:(options = {}, data)->

    options.cssClass   = "content-page activity"
    options.domId      = "content-page-activity"

    super options, data

    # FIXME: disable live updates - SY
    @appStorage = KD.getSingleton("appStorageController").storage 'Activity', '1.0.1'
    @appStorage.setValue 'liveUpdates', off


  viewAppended:->

    {entryPoint}      = KD.config
    windowController  = KD.singleton 'windowController'

    @feedWrapper      = new ActivityListContainer
    @inputWidget      = new ActivityInputWidget

    @referalBox       = new ReferalBox
    @groupListBox     = new UserGroupList
    @topicsBox        = new ActiveTopics
    @usersBox         = new ActiveUsers
    # @tickerBox        = new ActivityTicker
    # TODO : if not on private group DO NOT create those ~EA
    @groupDescription = new GroupDescription
    @groupMembers     = new GroupMembers

    @mainBlock        = new KDCustomHTMLView tagName : "main" #"activity-left-block"
    @sideBlock        = new KDCustomHTMLView tagName : "aside"   #"activity-right-block"

    @groupCoverView   = new FeedCoverPhotoView

    @mainController   = KD.getSingleton("mainController")
    @mainController.on "AccountChanged", @bound "decorate"
    @mainController.on "JoinedGroup", => @inputWidget.show()

    @feedWrapper.ready =>
      @activityHeader  = @feedWrapper.controller.activityHeader
      {@filterWarning} = @feedWrapper
      {feedFilterNav}  = @activityHeader
      feedFilterNav.unsetClass 'multiple-choice on-off'

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

    @decorate()

    @setLazyLoader 200

    @addSubView @groupCoverView
    @addSubView @mainBlock
    @addSubView @sideBlock

    topWidgetPlaceholder  = new KDCustomHTMLView
    leftWidgetPlaceholder = new KDCustomHTMLView

    @mainBlock.addSubView topWidgetPlaceholder
    @mainBlock.addSubView @inputWidget
    @mainBlock.addSubView @feedWrapper

    @sideBlock.addSubView @referalBox  if KD.isLoggedIn() and not @isPrivateGroup()
    @sideBlock.addSubView leftWidgetPlaceholder
    @sideBlock.addSubView @groupDescription if @isPrivateGroup()
    @sideBlock.addSubView @groupMembers if @isPrivateGroup() and ("list members" in KD.config.permissions)
    @sideBlock.addSubView @groupListBox  if KD.getGroup().slug is "koding"
    @sideBlock.addSubView @topicsBox
    @sideBlock.addSubView @usersBox if "list members" in KD.config.permissions
    # @sideBlock.addSubView @tickerBox

    KD.getSingleton("widgetController").showWidgets [
      { view: topWidgetPlaceholder,  key: "ActivityTop"  }
      { view: leftWidgetPlaceholder, key: "ActivityLeft" }
    ]

  isPrivateGroup :->
    {entryPoint} = KD.config
    if entryPoint?.slug isnt "koding" and entryPoint?.type is "group" then yes else no

  decorate:->
    @unsetClass "guest"
    {entryPoint, roles} = KD.config
    @setClass "guest" unless "member" in roles
    # if KD.isLoggedIn()
    @setClass 'loggedin'
    if entryPoint?.type is 'group' and 'member' not in roles
    then @inputWidget.hide()
    else @inputWidget.show()
    # else
    #   @unsetClass 'loggedin'
    #   @inputWidget.hide()
    @_windowDidResize()

  setTopicTag: (slug) ->
    return  if not slug or slug is ""
    KD.remote.api.JTag.one {slug}, null, (err, tag) =>
      @inputWidget.input.setDefaultTokens tags: [tag]

  unsetTopicTag: ->
    @inputWidget.input.setDefaultTokens tags: []


class ActivityListContainer extends JView

  constructor:(options = {}, data)->
    options.cssClass = "activity-content feeder-tabs"

    super options, data

    @pinnedListController = new PinnedActivityListController
      delegate    : this
      itemClass   : ActivityListItemView
      viewOptions :
        cssClass  : "hidden"

    @pinnedListWrapper = @pinnedListController.getView()

    @pinnedListController.on "Loaded", =>
      @togglePinnedList.show()
      @pinnedListController.getListView().show()

    @togglePinnedList = new KDCustomHTMLView
      cssClass   : "toggle-pinned-list hidden"
      # click      : KDView::toggleClass.bind @pinnedListWrapper, "hidden"

    @togglePinnedList.addSubView new KDCustomHTMLView
      tagName    : "span"
      cssClass   : "title"
      partial    : "Most Liked"

    @controller = new ActivityListController
      delegate          : @
      itemClass         : ActivityListItemView
      showHeader        : yes
      # wrapper           : no
      # scrollView        : no

    @listWrapper = @controller.getView()
    @filterWarning = new FilterWarning

    @controller.ready => @emit "ready"

  setSize:(newHeight)->
    # @controller.scrollView.setHeight newHeight - 28 # HEIGHT OF THE LIST HEADER

  viewAppended: ->
    super
    @togglePinnedList.show()  if @pinnedListController.getItemCount()

  pistachio:->
    """
      {{> @filterWarning}}
      {{> @togglePinnedList}}
      {{> @pinnedListWrapper}}
      {{> @listWrapper}}
    """

class FilterWarning extends JView

  constructor:->
    super cssClass : 'filter-warning hidden'

    @warning   = new KDCustomHTMLView
    @goBack    = new KDButtonView
      cssClass : 'goback-button'
      # todo - add group context here!
      callback : => KD.singletons.router.handleRoute '/Activity'

  pistachio:->
    """
    {{> @warning}}
    {{> @goBack}}
    """

  showWarning:({text, type})->
    partialText = switch type
      when "search" then "Results for <strong>\"#{text}\"</strong>"
      else "You are now looking at activities tagged with <strong>##{text}</strong>"

    @warning.updatePartial "#{partialText}"

    @show()
