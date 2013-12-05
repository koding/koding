class AppsAppController extends AppController

  handler = (callback)-> KD.singleton('appManager').open 'Apps', callback

  KD.registerAppClass this,
    name         : "Apps"
    routes       :
      "/:name?/Apps"             : handler
      "/:name?/Apps/:lala/:app?" : (arg)-> handler (app)-> app.handleRoute arg
    hiddenHandle : yes
    version      : "1.0"
    navItem      :
      title      : "Apps"
      path       : "/Apps"
      order      : 60

  constructor:(options = {}, data)->

    options.view    = new AppsMainView
      cssClass      : "content-page appstore"
    options.appInfo =
      name          : 'Apps'

    super options, data

    @on "LazyLoadThresholdReached", => @feedController.loadFeed()

  loadView:(mainView)->

    mainView.createCommons()
    @createFeed mainView

  createFeed:(view)->

    options =
      feedId                : 'apps.main'
      itemClass             : AppsListItemView
      limitPerPage          : 10
      delegate              : this
      useHeaderNav          : yes
      filter                :
        allApps             :
          title             : "All Apps"
          noItemFoundText   : "There is no application yet"
          dataSource        : (selector, options, callback)=>
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        updates             :
          title             : "Updates"
          noItemFoundText   : "No updates available"
          dataSource        : (selector, options, callback)=>
            if @appsController.publishedApps
              return @putUpdateAvailableApps callback
            @appsController.on "UserAppModelsFetched", =>
              @putUpdateAvailableApps callback
        webApps             :
          title             : "Web Apps"
          noItemFoundText   : "There are no web apps yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'web-app'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        kodingAddOns        :
          title             : "Add-ons"
          noItemFoundText   : "There are no add-ons yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'add-on'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        serverStacks        :
          title             : "Server Stacks"
          noItemFoundText   : "There are no server-stacks yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'server-stack'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        frameworks          :
          title             : "Frameworks"
          noItemFoundText   : "There are no frameworks yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'framework'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        miscellaneous       :
          title             : "Miscellaneous"
          noItemFoundText   : "There are no miscellaneous app yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'misc'
            KD.remote.api.JApp.someWithRelationship selector, options, callback

      sort                  :
        'meta.modifiedAt'   :
          title             : "Latest activity"
          direction         : -1
        'counts.followers'  :
          title             : "Most popular"
          direction         : -1
        'counts.tagged'     :
          title             : "Most activity"
          direction         : -1
      help                  :
        subtitle            : "Learn About Apps"
        bookIndex           : 26
        tooltip :
          title     : "<p class=\"bigtwipsy\">The App Catalog contains apps and Koding enhancements contributed to the community by users.</p>"
          placement : "above"
          offset    : 0
          delayIn   : 300
          html      : yes
          animate   : yes

    if KD.checkFlag 'super-admin'
      options.filter.waitsForApprove =
        title             : "New Apps"
        dataSource        : (selector, options, callback)=>
          selector.approved = no
          KD.remote.api.JApp.someWithRelationship selector, options, callback

    KD.getSingleton("appManager").tell 'Feeder', 'createContentFeedController', options, (controller)=>

      view.addSubView controller.getView()
      @feedController = controller
      @feedController.loadFeed()
      @emit 'ready'

  handleRoute:(route)->

    {app, lala} = route.params
    {JApp}      = KD.remote.api
    if app
      log "slug:", slug = "Apps/#{lala}/#{app}"
      JApp.one {slug}, (err, app)=>
        log "FOUND THIS JAPP", err, app
        if app then @showContentDisplay app

    log "HANDLING", route

  showContentDisplay:(content)->

    controller = new ContentDisplayControllerApps null, content
    contentDisplay = controller.getView()
    KD.singleton('display').emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplay
