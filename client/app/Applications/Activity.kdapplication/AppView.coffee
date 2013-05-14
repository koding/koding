class ActivityAppView extends KDScrollView

  headerHeight = 0

  constructor:(options = {}, data)->

    options.cssClass   = "content-page activity"
    options.domId      = "content-page-activity"

    super options, data

    @listenWindowResize()

    {entryPoint}      = KD.config
    HomeKonstructor   = if entryPoint and entryPoint.type isnt 'profile' then GroupHomeView else HomeAppView
    @feedWrapper      = new ActivityListContainer
    @innerNav         = new ActivityInnerNavigation cssClass : 'fl'
    @header           = new HomeKonstructor
    @widget           = new ActivityUpdateWidget
    @widgetController = new ActivityUpdateWidgetController view : @widget
    @mainController   = @getSingleton("mainController")

    @mainController.on "AccountChanged", @bound "decorate"
    @mainController.on "JoinedGroup", => @widget.show()
    @mainController.on "NavigationLinkTitleClick", @bound "navigateHome"
    # @on 'scroll', @utils.throttle @bound("changePageToActivity"), 250
    @on 'scroll', @bound("changePageToActivity")
    @header.bindTransitionEnd()

    @decorate()
    @setLazyLoader .99

    {scrollView} = @feedWrapper.controller
    @on "LazyLoadThresholdReached", scrollView.emit.bind scrollView, "LazyLoadThresholdReached"
    @header.on ["viewAppended", "ready"], => headerHeight = @header.getHeight()

  decorate:->
    if KD.isLoggedIn()
      @setClass 'loggedin'
      if KD.config.entryPoint?.type is 'group' and 'member' not in KD.config.roles
        @widget.hide()
      else
        @widget.show()
    else
      @unsetClass 'loggedin'
      @widget.hide()
    @_windowDidResize()

  changePageToActivity:(event)->
    return if @$().hasClass "fixed"
    if @getScrollTop() > headerHeight
      if KD.isLoggedIn()
        {navController} = @mainController.sidebarController.getView()
        navController.selectItemByName 'Activity'
        @setClass "fixed"
        @header.$().css marginTop : -headerHeight
      else
        @setClass "fixed"
    else
      @unsetClass "fixed" unless KD.isLoggedIn()


  navigateHome:(itemData)->

    switch itemData.pageName
      when "Home"
        @scrollTo {duration : 300, top : 0}, =>
          @unsetClass "fixed"
          @header.$().css marginTop : 0
      when "Activity"
        @header.once "transitionend", => @setClass "fixed"
        @header.$().css marginTop : -headerHeight

  _windowDidResize:->

    headerHeight = @header.getHeight()
    @innerNav.setHeight @getHeight() - (if KD.isLoggedIn() then 77 else 0)

  viewAppended:->

    $(".kdview.fl.common-inner-nav, .kdview.activity-content.feeder-tabs").remove()
    @addSubView @header
    @addSubView @widget
    @addSubView @innerNav
    @addSubView @feedWrapper

    # if KD.isLoggedIn()
    #   @utils.wait 1500, =>
    #     @navigateHome pageName :"Activity"


class ActivityListContainer extends JView

  constructor:(options = {}, data)->
    options.cssClass = "activity-content feeder-tabs"

    super options, data

    @controller = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : ActivityListItemView
      # wrapper           : no
      # scrollView        : no

    @listWrapper = @controller.getView()

    @utils.defer =>
      @getSingleton('activityController').emit "ActivityListControllerReady", @controller

  setSize:(newHeight)->
    # @controller.scrollView.setHeight newHeight - 28 # HEIGHT OF THE LIST HEADER

  pistachio:->
    """
      {{> @listWrapper}}
    """
