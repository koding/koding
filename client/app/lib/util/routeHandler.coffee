kd             = require 'kd'
lazyrouter     = require 'app/lazyrouter'

module.exports = (options) ->

  { title, name, homeRoute } = options

  handleSection = (path, callback)->

    { appManager, router, groupsController } = kd.singletons

    unless appManager.getFrontApp()
      appManager.once 'AppIsBeingShown', ->
        router.handleRoute path
      router.handleRoute '/IDE'
    else
      groupsController.ready ->
        appManager.open title, callback


  handle = (options, path) ->

    { query, params } = options
    { section, action, identifier } = params

    handleSection path, (app) ->
      app.openSection section, query, action, identifier


  lazyrouter.bind name, (type, info, state, path, ctx) ->
    switch type
      when 'home'
        kd.singletons.router.handleRoute homeRoute
      when 'section', 'action', 'identifier'
        handle info, path
