kd              = require 'kd'
lazyrouter      = require 'app/lazyrouter'

WelcomeModal = require 'home/welcome/welcomemodal'
IDEAppController = require 'ide'

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


  showWelcomeModal = (path) ->

    { appManager, router, groupsController } = kd.singletons

    frontApp = appManager.getFrontApp()
    unless frontApp
      appManager.once 'AppIsBeingShown', ->
        router.handleRoute path
      router.handleRoute '/IDE'
    else
      groupsController.ready ->
        modal = new WelcomeModal()
        return  unless frontApp instanceof IDEAppController

        modal.once 'KDObjectWillBeDestroyed', ->
          frontApp.showMachineStateModal()
        frontApp.hideMachineStateModal yes


  lazyrouter.bind name, (type, info, state, path, ctx) ->

    modalContainer = new ModalContainer

    switch type

      when 'group-disabled'

        { role, status } = info.params

        { appManager } = kd.singletons

        return handleDisabled role, status  if frontApp = appManager.getFrontApp()

        appManager.once 'AppIsBeingShown', -> handleDisabled role, status

        appManager.open 'IDE', { forceNew: yes }, (app) ->
          app.amIHost = yes
          appManager.tell 'IDE', 'showNoMachineState'

      when 'welcome'
        showWelcomeModal path
      when 'home'
        kd.singletons.router.handleRoute homeRoute
      when 'section', 'action', 'identifier'
        handle info, path


class ModalContainer
  constructor: ->
    @modal = null
    @container = new kd.CustomHTMLView
    @container.appendToDomBody()


  show: (modal) ->
    @modal?.destroy()
    @modal = modal
    @container.addSubView @modal  if @modal

handleDisabled = do (modalContainer = new ModalContainer) -> (role, status) ->

  DisabledAdminModal = require 'app/components/disabledmodals/admin'
  DisabledMemberModal = require 'app/components/disabledmodals/member'

  if role is 'Admin'
  then modalContainer.show new DisabledAdminModal { status }
  else modalContainer.show new DisabledMemberModal { status }

