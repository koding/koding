class DevToolsController extends AppController

  KD.registerAppClass this,
    name     : "DevTools"
    route    : "/DevTools"
    behavior : "application"
    multiple : yes
    openWith : "lastActive"
    cssClass : 'ace'

  constructor:(options = {}, data)->
    options.view    = new DevToolsMainView
    options.appInfo =
      name     : "DevTools"
      type     : "application"

    super options, data
