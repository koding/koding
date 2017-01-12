kd              = require 'kd'
lazyrouter      = require 'app/lazyrouter'

WelcomeModal = require 'home/welcome/welcomemodal'
IDEAppController = require 'ide'

module.exports = (options) ->

  { title, name, homeRoute } = options

  handleSection = (path, callback) ->

    { appManager, groupsController } = kd.singletons

    groupsController.ready ->
      if appManager.getFrontApp()
        appManager.open title, callback
      else
        appManager.open 'IDE', ->
          appManager.open title, callback


  handle = (options, path) ->

    { query, params, anchor } = options
    { section, action, identifier } = params

    handleSection path, (app) ->
      app.openSection { section, query, action, identifier, anchor }


  showWelcomeModal = (path) ->

    { appManager, router, groupsController } = kd.singletons

    frontApp = appManager.getFrontApp()

    showWelcome = ->
      modal = new WelcomeModal()

      if frontApp instanceof IDEAppController
        frontApp.hideMachineStateModal yes
        modal.once 'KDObjectWillBeDestroyed', ->
          frontApp.showMachineStateModal()

    groupsController.ready ->
      if appManager.getFrontApp()
      then showWelcome()
      else appManager.open 'IDE', -> showWelcome()


  lazyrouter.bind name, (type, info, state, path, ctx) ->

    modalContainer = new ModalContainer

    switch type
      when 'group-disabled'
        { role, status } = info.params
        { appManager } = kd.singletons
        if frontApp = appManager.getFrontApp()
          return handleDisabled role, status

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
