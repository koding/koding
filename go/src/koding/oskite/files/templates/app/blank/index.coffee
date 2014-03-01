class %%APPNAME%%MainView extends KDView

  constructor:(options = {}, data)->
    options.cssClass = '%%appname%% main-view'
    super options, data

  viewAppended:->
    @addSubView new KDView
      partial  : "Welcome to %%APPNAME%% app!"
      cssClass : "welcome-view"

class %%APPNAME%%Controller extends AppController

  constructor:(options = {}, data)->
    options.view    = new %%APPNAME%%MainView
    options.appInfo =
      name : "%%APPNAME%%"
      type : "application"

    super options, data

do ->

  # In live mode you can add your App view to window's appView
  if appView?

    view = new %%APPNAME%%MainView
    appView.addSubView view

  else

    KD.registerAppClass %%APPNAME%%Controller,
      name     : "%%APPNAME%%"
      routes   :
        "/:name?/%%APPNAME%%" : null
        "/:name?/Apps/%%AUTHOR%%/%%APPNAME%%/run" : null
      behavior : "application"