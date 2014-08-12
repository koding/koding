class AppsAppController extends AppController

  getAppInstance = (route, callback)->
    {app, username} = route.params
    return callback null  unless app
    KD.remote.api.JNewApp.one slug:"#{username}/Apps/#{app}", callback

  KD.registerAppClass this,
    name         : "Apps"
    hiddenHandle : yes
    searchRoute  : "/Apps?q=:text:"
    behaviour    : 'application'
    version      : "1.0"
    preCondition :
      condition  : (options, cb)-> cb KD.isLoggedIn() or KD.isLoggedInOnLoad
      failure    : (options, cb)->
        KD.singletons.appManager.open 'Apps', conditionPassed : yes
        KD.showEnforceLoginModal()

  constructor:(options = {}, data)->

    options.view    = new AppsMainView
      cssClass      : "content-page appstore"
    options.appInfo =
      name          : 'Apps'

    super options, data

    @_verifiedOnly = yes

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

    if selector['manifest.authorNick'] is KD.nick()
      @changeVerifiedSwitchVisibilty "hide"
    else
      @changeVerifiedSwitchVisibilty "show"
      if @_verifiedOnly
        selector['status'] = 'verified'

    KD.remote.api.JNewApp.some selector, options, callback

  changeVerifiedSwitchVisibilty: (methodName) ->
    @verifiedSwitch?[methodName]()
    @verifiedSwitchLabel?[methodName]()

  doKiteQuery:(selector, options, callback)->
    KD.remote.api.JKite.list selector, options, callback

  createFeed:(view, loadFeed = no)->

    options =
      feedId                : 'apps.main'
      itemClass             : AppsListItemView
      limitPerPage          : 12
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

        kites               :
          title             : "Kites"
          noItemFoundText   : "There are no kites yet"
          dataSource        : (selector, options, callback)=>
            @doKiteQuery selector, options, callback

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
    else
      delete options.filter.kites

    KD.getSingleton("appManager").tell 'Feeder', \
      'createContentFeedController', options, (controller)=>

        @verifiedSwitchLabel = new KDLabelView
          cssClass : 'verified-switch-label'
          title : "Verified applications only"

        @verifiedSwitch = new KodingSwitch
          cssClass      : 'verified-switch tiny'
          defaultValue  : @_verifiedOnly
          callback      : (state) =>
            @_verifiedOnly = state
            @feedController.reload()

        @_lastQuery = {}
        reloadButton = new KDButtonView
          style     : 'refresh-button transparent'
          title     : ''
          icon      : yes
          iconOnly  : yes
          callback  : =>
            @feedController.handleQuery @_lastQuery, force: yes

        kiteButton  = new KDButtonView
          title     : "Create New Kite"
          cssClass  : "solid mini green kite-button"
          callback  : =>
            kiteModal = new CreateKiteModal
            kiteModal.once "KiteCreated", =>
              @feedController.reload()

        facets = controller.facetsController.getView()
        facets.addSubView reloadButton
        facets.addSubView kiteButton

        feed = controller.getView()
        feed.addSubView @verifiedSwitchLabel
        feed.addSubView @verifiedSwitch

        view.addSubView @_lastSubview = feed

        @feedController = controller
        controller.loadFeed()  if loadFeed

        @emit 'ready'
        kiteButton.hide()

        controller.on "FilterChanged", (name) =>
          if name is "kites"
            @changeVerifiedSwitchVisibilty "hide"
            kiteButton.show()
          else
            @changeVerifiedSwitchVisibilty "show"
            kiteButton.hide()

  handleQuery:(query)->
    @ready =>
      if query.q? or @_searchValue
        @emit "searchFilterChanged", query.q or ""

      @feedController.handleQuery query
      @_lastQuery = query

  handleRoute:(route)->

    getAppInstance route, (err, app)=>
      if not err and app
      then @showContentDisplay app

  # Experimental ~ GG
  showAppDetailsModal:(app)->

    if @modal
      # To prevent going back to apps
      @modal.off "KDObjectWillBeDestroyed"
      @modal.destroy()

    appView = new AppDetailsView {cssClass : "app-details"}, app
    @modal  = new KDModalView
      view  : appView

    @modal.on "KDObjectWillBeDestroyed", =>
      @modal = null
      KD.singletons.router.clear "/Apps"

  showContentDisplay:(content)->

    controller = new ContentDisplayControllerApps null, content
    contentDisplay = controller.getView()
    KD.singleton('display').emit "ContentDisplayWantsToBeShown", contentDisplay
    return contentDisplay

  search:(text)-> @emit "searchFilterChanged", text
