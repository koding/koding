_ = require 'lodash'
kd = require 'kd'
AppController = require 'app/appcontroller'
StackEditorView = require './editor'
showError = require 'app/util/showError'
OnboardingView = require './onboarding/onboardingview'
EnvironmentFlux = require 'app/flux/environment'
ContentModal = require 'app/components/contentModal'
fetchOriginTemplate = require 'app/util/fetchorigintemplate'

do require './routehandler'
require 'stack-editor/styl'

module.exports = class StackEditorAppController extends AppController

  @options     = {
    name       : 'Stackeditor'
    behavior   : 'application'
  }

  constructor: (options = {}, data) ->

    super options, data

    # a cache to register created views.
    @editors = {}
    # a map of stack template ids for which editors should be reloaded
    @shouldReloadMap = {}

    @selectedEditor = null

    { router } = kd.singletons
    router.on 'RouteInfoHandled', (routeInfo) =>
      Object.keys(@shouldReloadMap).forEach @bound 'removeEditor'


  openEditor: (stackTemplateId = no, stackId) ->
    { mainController, groupsController, computeController } = kd.singletons

    unless groupsController.canEditGroup()
      mainController.tellChatlioWidget 'isShown', {}, (err, isShown) ->
        return if err
        return if isShown
        mainController.tellChatlioWidget 'show', { expanded: no }

    if stackTemplateId
      if @editors[stackTemplateId]
        { sidebar } = kd.singletons

        sidebar.setSelected
          templateId: stackTemplateId
          stackId: stackId
          machineId: null

        return  @showView { _id: stackTemplateId }

      computeController.fetchStackTemplate stackTemplateId, (err, stackTemplate) =>

        if err or not stackTemplate
          kd.singletons.router.handleRoute '/IDE'
          return showError err

        editor = @showView stackTemplate

        { sidebar } = kd.singletons

        sidebar.setSelected
          templateId: stackTemplateId
          stackId: stackId
          machineId: null

        # If selected template is deleted, then redirect them to ide.
        # TODO: show an information modal to the user if he/she is admin. ~Umut
        stackTemplate.on 'deleteInstance', =>
          return  if @selectedEditor.getData()._id isnt stackTemplate._id
          @selectedEditor = null
          @removeEditor stackTemplate._id
          kd.singletons.router.handleRoute '/IDE'

        fetchOriginTemplate stackTemplate, (err, originalTemplate) ->
          return  if err or not originalTemplate

          editor.addClonedFrom originalTemplate
          originalTemplate.on 'update', ->
            if stackTemplate.config.clonedSum isnt originalTemplate.template.sum
              return editor.addCloneUpdateView originalTemplate
          if stackTemplate.config.clonedSum isnt originalTemplate.template.sum
            editor.addCloneUpdateView originalTemplate

    else
      @showView()


  openStackWizard: (handleRoute = yes) ->

    modal = new kd.ModalView
      cssClass       : 'StackEditor-OnboardingModal'
      width          : 820
      overlay        : yes
      overlayOptions :
        cssClass     : 'second-overlay'


    view = new OnboardingView

    createOnce = do (isCreated = no) -> (selectedProvider) ->
      return  if isCreated
      isCreated = yes

      { router } = kd.singletons

      return router.handleRoute '/IDE'  unless selectedProvider

      EnvironmentFlux.actions.createStackTemplateWithDefaults selectedProvider
        .then ({ stackTemplate }) ->
          router.handleRoute "/Stack-Editor/#{stackTemplate._id}"

    view.on 'StackOnboardingCompleted', (selectedProvider) ->
      createOnce selectedProvider
      modal.destroy()

    view.on 'StackOnboardingCanceled', ->
      modal.destroy()

    modal.addSubView view

    if handleRoute
      modal.on 'KDObjectWillBeDestroyed', ->
        kd.singletons.router.back()


  showView: (stackTemplate) ->

    stackTemplate or= { _id: 'default' }

    id = stackTemplate._id

    unless @editors[id]
      @editors[id] = editor = @createEditor stackTemplate
      editor.on 'Reload', @lazyBound 'reloadEditor', stackTemplate._id
      @mainView.addSubView editor

    return  unless editor = @editors[id]

    # hide all editors
    Object.keys(@editors).forEach (templateId) =>
      view = @editors[templateId]

      view.getElement().removeAttribute 'testpath'
      view.hide()
      @selectedEditor = null

    # show the correct editor.
    editor.setAttribute 'testpath', 'StackEditor-isVisible'
    editor.show()
    @selectedEditor = editor

    { onboarding } = kd.singletons
    onboarding.run 'StackEditorOpened'

    return editor


  removeEditor: (templateId) ->

    editor = @editors[templateId]
    delete @editors[templateId]
    delete @shouldReloadMap[templateId]

    editor?.destroy()


  reloadEditor: (templateId, skipDataUpdate) ->

    return @markAsReloadRequired templateId  if skipDataUpdate

    EnvironmentFlux.actions.fetchAndUpdateStackTemplate(templateId)
      .then @lazyBound 'markAsReloadRequired', templateId


  markAsReloadRequired: (templateId) ->

    @shouldReloadMap[templateId] = yes  if @editors[templateId]?


  createEditor: (stackTemplate) ->

    template = if stackTemplate._id is 'default' then null else stackTemplate

    options = { cssClass: 'hidden', skipFullscreen: yes }
    data    = { stackTemplate: template, showHelpContent: not stackTemplate }

    view    = new StackEditorView options, data
    view.on 'Cancel', -> kd.singletons.router.back()

    confirmation = null

    view.on 'StackSaveInAction',  -> @_stackSaveInAction = yes
    view.on 'StackSaveCompleted', -> @_stackSaveInAction = no

    return view
