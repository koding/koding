kd             = require 'kd'
lazyrouter     = require 'app/lazyrouter'
registerRoutes = require 'app/util/registerRoutes'


handleSection = (path, callback)->

  { appManager, router, groupsController } = kd.singletons

  unless appManager.getFrontApp()
    appManager.once 'AppIsBeingShown', ->
      router.handleRoute path
    router.handleRoute '/IDE'
  else
    groupsController.ready ->
      appManager.open 'Admin', callback


handle = ({query, params:{section}}, path) ->
  handleSection path, (app) ->
    app.openSection section, query


module.exports = ->
  lazyrouter.bind 'admin', (type, info, state, path, ctx) ->
    switch type
      when 'home'
        kd.singletons.router.handleRoute '/Admin/Settings'
      when 'section'
        handle info, path
