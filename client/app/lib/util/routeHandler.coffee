kd              = require 'kd'
showError       = require 'app/util/showError'
remote          = (require 'app/remote').getInstance()
lazyrouter      = require 'app/lazyrouter'
EnvironmentFlux = require 'app/flux/environment'


WelcomeModal = require 'home/welcome/welcomemodal'

module.exports = (options) ->

  { title, name, homeRoute } = options

  handleSection = (path, callback) ->

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


  handleGitLab = (options, path) ->

    { params } = options
    { section, action, identifier, extra } = params

    repo = "#{identifier}/#{extra}"

    { groupsController, router, appManager } = kd.singletons

    notification = new kd.NotificationView
      title    : "Processing #{repo}..."
      duration : 10000

    appManager.once 'AppIsBeingShown', -> groupsController.ready ->

      { GitProvider } = remote.api
      GitProvider.importStackTemplateData

        provider : 'gitlab'
        url      : repo

      , (err, stackData) ->

        if showError err
          router.handleRoute '/Home/Stacks'
          notification.destroy()
          return

        GitProvider.createImportedStackTemplate null, stackData, (err, stack) ->

          notification.destroy()

          EnvironmentFlux.actions.loadPrivateStackTemplates()

          if showError err
            router.handleRoute '/Home/Stacks'
            return

          router.handleRoute "/Stack-Editor/#{stack._id}"


    router.handleRoute '/IDE'


  showWelcomeModal = (path) ->

    { appManager, router, groupsController } = kd.singletons

    unless appManager.getFrontApp()
      appManager.once 'AppIsBeingShown', ->
        router.handleRoute path
      router.handleRoute '/IDE'
    else
      groupsController.ready -> new WelcomeModal


  lazyrouter.bind name, (type, info, state, path, ctx) ->
    switch type
      when 'welcome'
        showWelcomeModal path
      when 'home'
        kd.singletons.router.handleRoute homeRoute
      when 'section', 'action', 'identifier'
        handle info, path
      when 'extra'
        handleGitLab info, path
