class %%APPNAME%%MainView extends KDView

  constructor:(options = {}, data)->
    options.cssClass = '%%APPNAME%% main-view'
    super options, data

  viewAppended:->
    @addSubView new KDView
      partial : "Welcome to %%APPNAME%% app!"

class %%APPNAME%%Controller extends AppController

  constructor:(options = {}, data)->
    options.view    = new %%APPNAME%%MainView
    options.appInfo =
      name     : "%%APPNAME%%"
      type     : "application"

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
        "/%%APPNAME%%" : null
        "/Apps/%%AUTHOR%%/%%APPNAME%%/run" : null
      behavior : "application"