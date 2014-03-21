class AppsAppController extends AppController

  handler = (callback)-> KD.singleton('appManager').open 'Apps', callback

  getAppInstance = (route, callback)->
    {app, username} = route.params
    return callback null  unless app
    KD.remote.api.JNewApp.one slug:"#{username}/Apps/#{app}", callback

  KD.registerAppClass this,
    name         : "Apps"
    enforceLogin : yes
    routes       :
      "/:name?/Apps" : ({params, query})->
        handler (app)-> app.handleQuery query
      "/:name?/Apps/:username/:app?" : (route)->
        {username} = route.params
        return  if username[0] is username[0].toUpperCase()
        handler (app)-> app.handleRoute route

    hiddenHandle : yes
    searchRoute  : "/Apps?q=:text:"
    behaviour    : 'application'
    version      : "1.0"

  constructor:(options = {}, data)->

    options.view    = new AppsMainView
      cssClass      : "content-page appstore"
    options.appInfo =
      name          : 'Apps'

    super options, data

    @_verifiedOnly = no

  loadView:(mainView, firstRun = yes, loadFeed = no)->
    if firstRun

      @on "searchFilterChanged", (value) =>
        return if value is @_searchValue

        @_searchValue = Encoder.XSSEncode value
        @_lastSubview.destroy?()
        @loadView mainView, no, yes

      mainView.createCommons()

    @createFeed mainView, loadFeed

  doQuery:(selector, options, callback)->
    if @_verifiedOnly then selector['status'] = 'verified'
    KD.remote.api.JNewApp.some selector, options, callback

  createFeed:(view, loadFeed = no)->

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
            {JNewApp} = KD.remote.api
            if @_searchValue
            then JNewApp.byRelevance @_searchValue, options, callback
            else @doQuery selector, options, callback

        myApps              :
          title             : "My Apps"
          noItemFoundText   : "You don't have any apps yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.authorNick'] = KD.nick()
            @doQuery selector, options, callback

        webApps             :
          title             : "Web Apps"
          noItemFoundText   : "There is no web apps yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'web-app'
            @doQuery selector, options, callback

        kodingAddOns        :
          title             : "Add-ons"
          noItemFoundText   : "There is no add-ons yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'add-on'
            @doQuery selector, options, callback

        serverStacks        :
          title             : "Server Stacks"
          noItemFoundText   : "There is no server-stacks yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'server-stack'
            @doQuery selector, options, callback

        frameworks          :
          title             : "Frameworks"
          noItemFoundText   : "There is no frameworks yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'framework'
            @doQuery selector, options, callback

        miscellaneous       :
          title             : "Miscellaneous"
          noItemFoundText   : "There is no miscellaneous app yet"
          dataSource        : (selector, options, callback)=>
            selector['manifest.category'] = 'misc'
            @doQuery selector, options, callback

      sort                  :

        'meta.modifiedAt'   :
          title             : "Latest activity"
          direction         : -1

    if KD.checkFlag 'super-admin'
      options.filter.waitsForApprove =
        title             : "New Apps"
        dataSource        : (selector, options, callback)=>
          KD.remote.api.JNewApp.some_ selector, options, callback

    KD.getSingleton("appManager").tell 'Feeder', \
      'createContentFeedController', options, (controller)=>

        @_verifiedSwitchLabel = new KDLabelView
          cssClass : 'verified-switch-label'
          title : "Verified applications only"

        @_verifiedSwitch = new KodingSwitch
          cssClass      : 'verified-switch tiny'
          defaultValue  : @_verifiedOnly
          callback      : (state) =>
            @_verifiedOnly = state
            @feedController.reload()

        feed = controller.getView()
        feed.addSubView @_verifiedSwitchLabel
        feed.addSubView @_verifiedSwitch

        view.addSubView @_lastSubview = feed
        @feedController = controller
        controller.loadFeed()  if loadFeed
        @emit 'ready'

  handleQuery:(query)->
    @ready =>
      if query.q? or @_searchValue
        @emit "searchFilterChanged", query.q or ""
      @feedController.handleQuery query, force: yes

  handleRoute:(route)->

    getAppInstance route, (err, app)=>
      if not err and app then @showContentDisplay app

  showContentDisplay:(content)->

    controller = new ContentDisplayControllerApps null, content
    contentDisplay = controller.getView()
    KD.singleton('display').emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplay

  search:(text)-> @emit "searchFilterChanged", text

