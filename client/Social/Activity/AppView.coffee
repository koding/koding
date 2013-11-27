class ActivityAppView extends KDScrollView

  headerHeight = 0

  constructor:(options = {}, data)->

    options.cssClass   = "content-page activity"
    options.domId      = "content-page-activity"

    super options, data

    @listenWindowResize()

  viewAppended:->

    {entryPoint}      = KD.config

    if entryPoint in ['koding', 'guest']
      @setClass 'fixed'
    else if entryPoint?.type is 'profile'
      @setClass 'fixed'

    HomeKonstructor   = if entryPoint and entryPoint.type isnt 'profile' then GroupHomeView else KDCustomHTMLView
    @feedWrapper      = new ActivityListContainer
    @innerNav         = new ActivityInnerNavigation cssClass : 'fl'
    @header           = new HomeKonstructor
    @inputWrapper     = new KDView cssClass: "input-wrapper"
    @rightBlock       = new ActivityTicker
    @leftBlock        = new KDCustomHTMLView cssClass : "activity-left-block"
    @mainController   = KD.getSingleton("mainController")

    @inputWrapper.addSubView @input = new ActivityInputView

    @inputWrapper.addSubView new KDButtonView
      type     : "submit"
      cssClass : "fr"
      title    : "Submit"
      callback : =>
        @input.submit (err, activity) =>
          @emit "InputSubmitted", activity  unless err

    @mainController.on "AccountChanged", @bound "decorate"
    @mainController.on "JoinedGroup", => @inputWrapper.show()

    @header.bindTransitionEnd()

    @feedWrapper.ready =>
      @activityHeader = @feedWrapper.controller.activityHeader
      @on 'scroll', (event) =>
        if event.delegateTarget.scrollTop > 50
          @activityHeader.setClass "scrolling-up-outset"
          @activityHeader.liveUpdateButton.setValue off
        else
          @activityHeader.unsetClass "scrolling-up-outset"
          @activityHeader.liveUpdateButton.setValue on
          KD.getSingleton("activityController").clearNewItemsCount()

    @decorate()

    @setLazyLoader 200

    @header.on ["viewAppended", "ready"], => headerHeight = @header.getHeight()

    $(".kdview.fl.common-inner-nav, .kdview.activity-content.feeder-tabs").remove()
    @addSubView @header
    @addSubView @innerNav
    @addSubView @leftBlock
    @addSubView @rightBlock

    @leftBlock.addSubView @inputWrapper
    @leftBlock.addSubView @feedWrapper

  decorate:->
    @unsetClass "guest"
    {entryPoint, roles} = KD.config
    @setClass "guest" unless "member" in roles
    # if KD.isLoggedIn()
    @setClass 'loggedin'
    if entryPoint?.type is 'group' and 'member' not in roles
    then @inputWrapper.hide()
    else @inputWrapper.show()
    # else
    #   @unsetClass 'loggedin'
    #   @inputWrapper.hide()
    @_windowDidResize()

  # changePageToActivity:(event)->

  #   if KD.isLoggedIn()
  #     if not @$().hasClass("fixed") and @getScrollTop() > headerHeight - 10
  #       {navController} = @mainController.sidebarController.getView()
  #       navController.selectItemByName 'Activity'
  #       @setClass "fixed"
  #       @header.once "transitionend", @header.bound "hide"
  #       @header.$().css marginTop : -headerHeight
  #       KD.getSingleton('mainViewController').emit "browseRequested"

  # navigateHome:(itemData)->

  #   switch itemData.pageName
  #     when "Home"
  #       @header.show()
  #       @header._windowDidResize()
  #       @scrollTo {duration : 300, top : 0}, =>
  #         # if KD.isLoggedIn()
  #         @unsetClass "fixed"
  #         @header.$().css marginTop : 0
  #     when "Activity"
  #       if KD.isLoggedIn()
  #         @header.once "transitionend", =>
  #           @header.hide()
  #           @setClass "fixed"
  #         @header.$().css marginTop : -headerHeight
  #       else
  #         @scrollTo {duration : 300, top : @header.getHeight()}

  _windowDidResize:->
    return unless @header
    headerHeight = @header.getHeight()
    @innerNav.setHeight @getHeight() - 77 # (if KD.isLoggedIn() then 77 else 0)



class ActivityListContainer extends JView

  constructor:(options = {}, data)->
    options.cssClass = "activity-content feeder-tabs"

    super options, data

    @controller = new ActivityListController
      delegate          : @
      itemClass         : ActivityListItemView
      showHeader        : yes
      # wrapper           : no
      # scrollView        : no

    @listWrapper = @controller.getView()

    @controller.ready => @emit "ready"

  setSize:(newHeight)->
    # @controller.scrollView.setHeight newHeight - 28 # HEIGHT OF THE LIST HEADER

  pistachio:->
    """
      {{> @listWrapper}}
    """
