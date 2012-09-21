class PageEnvironment extends KDView
  viewAppended:->
      
    @addSubView comingSoonOverlay = new ComingSoonOverlay

    @addSubView mainContainer = new KDView cssClass : "environment-view-wrapper"
    new EnvironmentController view : mainContainer


class ComingSoonOverlay extends KDView
  viewAppended:()->
    @setClass "coming-soon-page comingsoon-overlay"
    @setPartial @partial

  partial:()->
    partial = $ "<div class='comingsoon'>
            <!--<img src='../images/appsbig.png' alt='Environments are coming soon!'>-->
            <h1>Server Settings</h1>
            <h2>Coming soon</h2>
            <p>The server settings area will contain statistics and settings for your deployment server, database management deploy target management and more.</p>
        </div>"

    
class EnvironmentController extends KDViewController
  viewMenuItems :
    type : "view-menu"
    items : [
        { title : 'Server',         id : 'server' }
        { title : 'Usage',          id : 'usage' }
        { title : 'Top Processes',  id : 'top_processes' }
        { title : 'Projects',       id : 'projects' }
        { title : 'My Mounts',      id : 'mounts' }
        { title : 'Repositories',   id : 'repositories' }
        { title : 'People',         id : 'people' }
      ]

  envData :
    title : "sinan.koding.com"
    tags : ["PHP","PYTHON","PERL","RUBY"]
    load : ["2.07","1.64","1.73"]
    uptime : "34d 23m 23s"
  

  loadView:(mainView)->
    {profile} = KD.whoami()    
    header = mainView.header = new EnvironmentHeader type : "big", title : profile.nickname
    menu = mainView.menu = new EnvironmentViewMenu null,@viewMenuItems

    environmentView = mainView.environmentView = new EnvironmentView cssClass : "environment-view server",@envData #server cssClass is for server filter

    @listenTo 
      KDEventTypes : "EnvironmentLaunchEditor"
      listenedToInstance : header
      callback : @launchEditor
    
    mainView.environmentSplit = @environmentSplit = new ContentPageSplitBelowHeader
      cssClass  : "environment-pane-split"
      views     : [menu,environmentView]
      sizes     : [139,null]


    menu.setHeight "auto"
    environmentView.setHeight "auto"

    mainView.headerSplit = new SplitView
      cssClass  : "environment-header-split"
      views     : [header,@environmentSplit]
      sizes     : [77,null]
      type      : "horizontal"
      resizable : no
    
    mainView.addSubView mainView.headerSplit
    mainView.environmentView.init()

  launchEditor:=>
    log "launchEditor",":::"
    

class EnvironmentView extends KDView
  init:->
    @addSubView envHeader = new EnvironmentViewSummary (cssClass : "environment-header-wrapper"), @getData()
    @addSubView envUsage = new EnvironmentViewUsage
    @addSubView envTopProcesses = new EnvironmentViewTopProcesses
    @addSubView envTopProcesses = new EnvironmentViewMounts

class EnvironmentHeader extends KDHeaderView

  viewAppended:->
    @setClass "header-view-section"
    @setPartial "<cite>Default Environment</cite>"

    @addSubView launchEditorButtonHolder = new KDView
      cssClass : "button-holder"

    launchEditorButtonHolder.addSubView launchEditorButton = new KDButtonView
      title     : "Launch Editor"
      style     : "gray-bevel"
      icon      : yes
      iconClass : "terminal"
      callback  : ()=> @handleEvent type : "EnvironmentLaunchEditor"
