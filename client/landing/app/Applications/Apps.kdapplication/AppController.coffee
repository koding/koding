class AppsAppController extends AppController

  KD.registerAppClass this,
    name         : "Apps"
    route        : "/Apps"
    hiddenHandle : yes

  constructor:(options = {}, data)->

    options.view    = new AppsMainView
      cssClass      : "content-page appstore"
    options.appInfo =
      name          : 'Apps'

    super options, data

    @appsController = KD.getSingleton "kodingAppsController"

    @appsController.on "AnAppHasBeenUpdated", @bound "updateApps"

  loadView:(mainView)->

    mainView.createCommons()
    @createFeed()

  createFeed:(view)->

    options =
      itemClass             : AppsListItemView
      limitPerPage          : 10
      noItemFoundText       : "There is no app."
      filter                :
        allApps             :
          title             : "All Apps"
          dataSource        : (selector, options, callback)=>
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        updates             :
          title             : "Updates"
          dataSource        : (selector, options, callback)=>
            if @appsController.publishedApps
              return @putUpdateAvailableApps callback
            @appsController.on "UserAppModelsFetched", =>
              @putUpdateAvailableApps callback
        webApps             :
          title             : "Web Apps"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'web-app'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        kodingAddOns        :
          title             : "Add-ons"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'add-on'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        serverStacks        :
          title             : "Server Stacks"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'server-stack'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
        frameworks          :
          title             : "Frameworks"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'framework'
            KD.remote.api.JApp.someWithRelationship selector, options, callback
            callback 'Coming soon!'
        miscellaneous       :
          title             : "Miscellaneous"
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
      for own name,listController of controller.resultsController.listControllers
        listController.getListView().on 'AppWantsToExpand', (app)->
          KD.getSingleton('router').handleRoute "/Apps/#{app.slug}", state: app

      @getView().addSubView controller.getView()
      @feedController = controller
      @emit 'ready'

      {updateAppsButton} = @getView()
      if controller.selection.name is 'updates'
        updateAppsButton.emit 'UpdateView', 'updates'

      controller.on 'FilterChanged', (filter)=>
        @updateApps()  if filter is 'updates'
        updateAppsButton.emit 'UpdateView', filter

  putUpdateAvailableApps: (callback) ->
    @appsController.fetchUpdateAvailableApps callback

  updateApps:->
    @utils.wait 100, => @feedController?.changeActiveSort "meta.modifiedAt"

  createContentDisplay:(app, callback)->
    contentDisplay = @showContentDisplay app
    @utils.defer => callback contentDisplay

  showContentDisplay:(content)->
    contentDisplayController = KD.getSingleton "contentDisplayController"
    controller = new ContentDisplayControllerApps null, content
    contentDisplay = controller.getView()
    contentDisplayController.emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplay