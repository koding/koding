class ActivityAppView extends JView

  constructor:(options = {}, data)->

    options.cssClass = "content-page activity"

    super options, data

    account        = KD.whoami()
    feedWrapper    = new ActivityListContainer
    @innerNav      = new ActivityInnerNavigation

    @header = new WelcomeHeader
      type      : "big"
      title     : if KD.isLoggedIn() then\
        "Hi #{account.profile.firstName}! Welcome to the Koding Public Beta." else\
        "Welcome to the Koding Public Beta!<br>"
      subtitle  : "Warning! when we say beta - <a href='#'>we mean it</a> :)"

    @split = new ActivitySplitView
      views     : [@innerNav, feedWrapper]
      delegate  : @

    @widget = new ActivityUpdateWidget

    @widget.hide()  unless KD.isLoggedIn()

    @widgetController = new ActivityUpdateWidgetController
      view : @widget

    @getSingleton("mainController").once "AccountChanged", (account)=>
      @widget[if KD.isLoggedIn() then "show" else "hide"]()
      @notifyResizeListeners()

    @split.on "ViewResized", =>
      feedWrapper.setSize @split.getHeight()

    @utils.wait 1000, @notifyResizeListeners.bind @

    @header.hide()  if localStorage.welcomeMessageClosed

  pistachio:->
    """
      {{> @header}}
      {{> @widget}}
      {{> @split}}
    """

class ActivityListContainer extends JView

  constructor:(options = {}, data)->

    options.cssClass = "activity-content feeder-tabs"

    super options, data

    @controller = new ActivityListController
      delegate          : @
      lazyLoadThreshold : .99
      itemClass         : ActivityListItemView

    @listWrapper = @controller.getView()

    @utils.wait =>
      @getSingleton('activityController').emit "ActivityListControllerReady", @controller

  setSize:(newHeight)->
    @controller.scrollView.setHeight newHeight - 28 # HEIGHT OF THE LIST HEADER

  pistachio:->
    """
      {{> @listWrapper}}
    """
