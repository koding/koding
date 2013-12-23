class DevToolsController extends AppController

  KD.registerAppClass this,
    name         : "DevTools"
    route        : "/DevTools"
    behavior     : "application"
    multiple     : yes
    openWith     : "lastActive"

  constructor:(options = {}, data)->
    options.view    = new DevToolsMainView
    options.appInfo =
      name     : "DevTools"
      type     : "application"
      cssClass : "ace"

    super options, data
