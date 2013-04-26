class ActivityAppView extends KDScrollView

  headerHeight = 0

  constructor:(options = {}, data)->

    options.cssClass = "content-page activity"
    options.domId    = "content-page-activity"

    super options, data

    @listenWindowResize()

    entryPoint        = KD.config.groupEntryPoint
    HomeKonstructor   = if entryPoint then GroupHomeView else HomeAppView
    @feedWrapper      = new ActivityListContainer
    @innerNav         = new ActivityInnerNavigation cssClass : 'fl'
    @header           = new HomeKonstructor {entryPoint}
    @widget           = new ActivityUpdateWidget
    @widgetController = new ActivityUpdateWidgetController view : @widget
    mainController    = @getSingleton("mainController")

    mainController.on "AccountChanged", @bound "decorate"
    mainController.on "NavigationLinkTitleClick", @bound "navigateHome"
    @on 'scroll', @utils.throttle @bound("setFixed"), 250

    @decorate()
    @setLazyLoader .99

    {scrollView} = @feedWrapper.controller
    @on "LazyLoadThresholdReached", scrollView.emit.bind scrollView, "LazyLoadThresholdReached"
    @header.on ["viewAppended", "ready"], => headerHeight = @header.getHeight()

  decorate:->
    if KD.isLoggedIn()
      @setClass 'loggedin'
      @widget.show()
      @header.$('.home-links').addClass 'hidden'
    else
      @unsetClass 'loggedin'
      @widget.hide()
      @header.$('.home-links').removeClass 'hidden'
    @_windowDidResize()

  setFixed:->
    pre = if @getScrollTop() > headerHeight = @header.getHeight() then "set" else "unset"
    @["#{pre}Class"] "fixed"

  navigateHome:(itemData)->

    top      = if itemData.pageName is "Home" then 0 else @header.getHeight()
    duration = 300

    @scrollTo {top, duration} if itemData.pageName in ["Home", "Activity"]

  _windowDidResize:->

    headerHeight = @header.getHeight()
    @innerNav.setHeight @getHeight() - (if KD.isLoggedIn() then 77 else 0)

  viewAppended:->
    log "here >>>>>>>>>"
    $(".kdview.fl.common-inner-nav, .kdview.activity-content.feeder-tabs").remove()
    @addSubView @header
    @addSubView @widget
    @addSubView @innerNav
    @addSubView @feedWrapper

  # pistachio:->
  #   """
  #     {{> @header}}
  #     {{> @widget}}
  #     {{> @innerNav}}
  #     {{> @feedWrapper}}
  #   """

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
