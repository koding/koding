kd             = require 'kd'
lazyrouter     = require 'app/lazyrouter'


handleSection = (path, callback)->

  { appManager, router, groupsController } = kd.singletons

  unless appManager.getFrontApp()
    appManager.once 'AppIsBeingShown', ->
      router.handleRoute path
    router.handleRoute '/IDE'
  else
    groupsController.ready ->
      appManager.open 'Stacks', callback


handle = (options, path) ->

  { query, params } = options
  { section, action, identifier } = params

  handleSection path, (app) ->
    app.openSection section, query, action, identifier


module.exports = ->
  lazyrouter.bind 'stacks', (type, info, state, path, ctx) ->
    switch type
      when 'home'
        kd.singletons.router.handleRoute '/Stacks/Your-Stacks'
      when 'section', 'action', 'identifier'
        handle info, path
