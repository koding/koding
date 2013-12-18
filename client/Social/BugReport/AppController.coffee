class BugReportController extends AppController

  KD.registerAppClass this,
    name         : "BugReport"
    route        : "/BugReport"
    behaviour    : 'application'
    version      : "1.0"
    navItem      :
      title      : "Bug Reports"
      path       : "/BugReport"
      order      : 60

  constructor:(options = {}, data)->
    options.view    = new BugReportMainView
      cssClass      : "content-page bugreports"
    options.appInfo =
      name          : 'Bugs'
    super options, data

  loadView:(mainView)->
    mainView.createCommons()
    @createFeed mainView

  createFeed: (view)->
    options =
      feedId               : 'apps.bugreport'
      itemClass            : BugStatusItemList
      limitPerPage         : 10
      useHeaderNav         : yes
      filter               :
        allbugs            :
          title            : "Reported Bugs"
          noItemFoundText  : "There is no reported bugs"
          dataSource       : (selector, options, callback) =>
            selector       =
              limit        : 20
              slug         : "bug"
            KD.remote.api.JNewStatusUpdate.fetchTopicFeed selector, callback
      sort                 :
        'meta.modifiedAt'  :
          title            : "Latest Bugs"
          direction        : -1

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', options, (controller)=>
      view.addSubView controller.getView()
      @feedController = controller
      @emit 'ready'

class BugStatusItemList extends KDListItemView

  constructor:( options={}, data)->
    options.cssClass = "activity-item status"
    super options, data

    @statusItem = new StatusActivityItemView options, data
    @bugstatus = new KDMultipleChoice
      cssClass     : "clean-gray editor-button control-button"
      labels       : ["fixed", "postponed", "not repro","duplicate","by design"]
      multiple     : no
      defaultValue : "done"
      size         : "tiny"
      callback     : (value)=>
        log "NOT IMPLEMENTED YET!"

    @loadSystemTags()

  loadSystemTags:->
    {JTag} = KD.remote.api
    JTag.fetchSystemTags {},limit:50, (err, tags)->
      log "NOT IMPLEMENTED YET!"

  viewAppended: JView::viewAppended

  pistachio: ->
    """
    {{> @statusItem}}
    {{> @bugstatus}}
    """
