class AppsMainView extends KDView
  constructor:(options,data)->
    options = $.extend
      ownScrollBars : yes
    ,options
    super options,data

  createCommons:->
    # @setClass "coming-soon-page"
    # @setPartial @partial
    @addSubView header = new HeaderViewSection type : "big", title : "App Catalog"
    # @addSubView new CommonFeedMessage
    #   title           : "<p>The App Catalog contains apps and Koding enhancements contributed to the community by our users. We'll be releasing documentation for app submission in the near future.</p>"
    #   messageLocation : 'AppStore'

  # partial:()->
  #   """
  #     <div class='comingsoon'>
  #         <img src='../images/appsbig.png' alt='Topics are coming soon!'><h1>Koding Apps</h1>
  #         <h2>Coming soon</h2>
  #         <p>The Koding App catalog will contain the popular web apps, frameworks and goodies you are used to, along with the ability to create your own apps to share with the Koding community.</p>
  #     </div>
  #   """

  showContentDisplay:(content,contentType)->
    contentDisplayController = @getSingleton "contentDisplayController"
    controller = new ContentDisplayControllerApps null, content
    contentDisplay = controller.getView()
    contentDisplayController.emit "ContentDisplayWantsToBeShown",contentDisplay

  _windowDidResize:()=>
    # @appsSplitView.setRightColumnClass()
    # @appsSplitView.panels[1].$(".listview-wrapper").height @appsSplitView.getHeight() - 28

