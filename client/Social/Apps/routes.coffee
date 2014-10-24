do ->

  handler = (callback)-> KD.singleton('appManager').open 'Apps', callback

#  KD.registerRoutes 'Apps',
#    "/:name?/Apps" : ({params, query})->
#      handler (app)-> app.handleQuery query
#    "/:name?/Apps/:username/:app?" : (route)->
#      {username} = route.params
#      return  if username[0] is username[0].toUpperCase()
#      handler (app)-> app.handleRoute route

