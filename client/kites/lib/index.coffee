kd = require 'kd'
$ = require 'jquery'
KDNotificationView = kd.NotificationView
KiteDetailsView = require './views/kitedetailsview'
showError = require 'app/util/showError'
AppController = require 'app/appcontroller'
remote = require('app/remote').getInstance()


module.exports = class KitesAppController extends AppController

  @options =
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
    {currentPath} = kd.getSingleton "router"

    # an example full query is "/Kites/fatihacet/MyKite"
    # so temp = "/", route = "Kites", username = "fatihacet", kiteName = "MyKite"
    [temp, route, username, kiteName] = currentPath.split "/"

    if (not username and not kiteName) or (username and not kiteName)
      return @goToKites()

    @displayKiteContent username, kiteName

  goToKites: ->
    kd.getSingleton("router").handleRoute "/Apps?filter=kites"

  displayKiteContent: (username, kiteName) ->
    query =
      "manifest.name"       : kiteName
      "manifest.authorNick" : username

    remote.api.JKite.list query, {}, (err, kite) =>
      return showError err  if err

      unless kite.length
        new KDNotificationView
          type     : "mini"
          cssClass : "error"
          title    : "There is no kite named #{kiteName}"
          duration : 4000

        return @goToKites()

      $("body").addClass "apps"
      @getView().addSubView new KiteDetailsView {}, kite.first
