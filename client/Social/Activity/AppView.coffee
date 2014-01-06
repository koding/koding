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

    @tickerBox        = new ActivityTicker
    @usersBox         = new ActiveUsers
    @topicsBox        = new ActiveTopics

    @mainBlock        = new KDCustomHTMLView tagName : "main" #"activity-left-block"
    @sideBlock        = new KDCustomHTMLView tagName : "aside"   #"activity-right-block"

    @mainController   = KD.getSingleton("mainController")
    @mainController.on "AccountChanged", @bound "decorate"
    @mainController.on "JoinedGroup", => @inputWidget.show()

    @feedWrapper.ready =>
      @activityHeader  = @feedWrapper.controller.activityHeader
      {@filterWarning} = @feedWrapper
      {feedFilterNav}  = @activityHeader
      feedFilterNav.unsetClass 'multiple-choice on-off'

    @tickerBox.once 'viewAppended', =>
      topOffset = @tickerBox.$().position().top
      windowController.on 'ScrollHappened', =>
        if document.body.scrollTop > topOffset
        then @tickerBox.setClass 'fixed'
        else @tickerBox.unsetClass 'fixed'

    @decorate()

    @setLazyLoader 200

    @addSubView @mainBlock
    @addSubView @sideBlock

    @mainBlock.addSubView @inputWidget
    @mainBlock.addSubView @feedWrapper

    @sideBlock.addSubView @topicsBox
    @sideBlock.addSubView @usersBox
    @sideBlock.addSubView @tickerBox

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
    @filterWarning = new FilterWarning

    @controller.ready => @emit "ready"

  setSize:(newHeight)->
    # @controller.scrollView.setHeight newHeight - 28 # HEIGHT OF THE LIST HEADER

  pistachio:->
    """
      {{> @filterWarning}}
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
