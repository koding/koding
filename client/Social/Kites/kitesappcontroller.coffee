class KitesAppController extends AppController

  KD.registerAppClass this,
    name            : "Kites"
    route           : "/:name?/Kites?/:username?/:kite?"
    enforceLogin    : yes
    hiddenHandle    : yes
    searchRoute     : "/Kites?q=:text:"
    behaviour       : 'application'
    version         : "1.0"

  constructor:(options = {}, data)->
    options.appInfo =
      name          : "Kites"
      type          : "applications"

    super options, data

  handleQuery: (query) ->
    {currentPath} = KD.getSingleton "router"

    # an example full query is "/Kites/fatihacet/MyKite"
    # so temp = "/", route = "Kites", username = "fatihacet", kiteName = "MyKite"
    [temp, route, username, kiteName] = currentPath.split "/"

    if (not username and not kiteName) or (username and not kiteName)
      return @goToKites()

    @displayKiteContent username, kiteName

  goToKites: ->
    KD.getSingleton("router").handleRoute "/Apps?filter=kites"

  displayKiteContent: (username, kiteName) ->
    query =
      "manifest.name"       : kiteName
      "manifest.authorNick" : username

    KD.remote.api.JKite.list query, {}, (err, kite) =>
      return KD.showError err  if err

      unless kite.length
        new KDNotificationView
          type     : "mini"
          cssClass : "error"
          title    : "There is no kite named #{kiteName}"
          duration : 4000

        return @goToKites()

      $("body").addClass "apps"
      @getView().addSubView new KiteDetailsView {}, kite.first
