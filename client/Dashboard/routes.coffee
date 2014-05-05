do ->

  handler = (group, callback)->
    KD.getSingleton('groupsController').ready ->
      KD.singleton('appManager').open 'Dashboard', callback

  KD.registerRoutes 'Dashboard',
    "/:name?/Dashboard"          : ({params : {section,name}})->
      handler name, (app)-> app.loadSection title : "Settings"
    "/:name?/Dashboard/:section" : ({params : {section,name}})->
      handler name, (app)-> app.loadSection title : decodeURIComponent section
